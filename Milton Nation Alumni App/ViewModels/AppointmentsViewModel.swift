import Foundation
import Observation
import Supabase

/// Push body for a single-user appointment notification. Keys match what the
/// send-push-notification function reads (target/userId/title/body) — the
/// invoke encoder does not snake-case, so `userId` arrives as `userId`.
private struct AppointmentPushParams: Encodable {
    let target: String
    let userId: String
    let title: String
    let body: String
}

/// Drives both the client "My Sessions" surface and the staff scheduling
/// console. RLS decides which appointments come back; this only shapes them.
@MainActor
@Observable
final class AppointmentsViewModel {
    private let dataService: DataServiceProtocol

    var appointments: [Appointment] = []
    var isLoading = false
    var errorMessage: String?

    /// Cached so a just-completed session can show its rating without a refetch.
    var feedbackByAppointment: [UUID: AppointmentFeedback] = [:]

    init(dataService: DataServiceProtocol = DefaultServices.dataService) {
        self.dataService = dataService
    }

    // MARK: - Derived slices

    var upcoming: [Appointment] {
        appointments.filter { $0.isUpcoming }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    var past: [Appointment] {
        appointments.filter { !$0.isUpcoming }
            .sorted { ($0.scheduledStart ?? .distantPast) > ($1.scheduledStart ?? .distantPast) }
    }

    /// Pending requests a provider hasn't confirmed yet — surfaced to staff.
    var pendingRequests: [Appointment] {
        appointments.filter { $0.status == .requested }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            appointments = try await dataService.fetchAppointments()
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.load")
            errorMessage = "Couldn't load your sessions. Pull to refresh."
        }
    }

    // MARK: - Mutations

    /// Providers a client may request (all facility clinical staff + admins).
    var bookableProviders: [BookableProvider] = []
    /// Load lifecycle so the request sheet can distinguish "still loading" from
    /// "loaded, and there are genuinely none" from "the load failed" — instead
    /// of spinning forever on any RPC error (was a silent `try?`).
    var providersLoaded = false
    var providersLoadFailed = false

    func loadBookableProviders() async {
        providersLoadFailed = false
        do {
            bookableProviders = try await dataService.fetchBookableProviders()
            providersLoaded = true
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.loadBookableProviders")
            providersLoadFailed = true
            providersLoaded = true   // resolved (with an error) — stop the spinner
        }
    }

    /// Fill in provider display names the `profiles` RLS won't return to a
    /// client. A client can only read their OWN + assigned staff profiles, so
    /// the `provider:profiles(full_name)` embed comes back nil for a provider
    /// they were matched with but aren't formally assigned to — leaving cards
    /// showing the generic "Your provider." We already hold every facility
    /// provider's name from `bookable_providers()` for the picker; reuse it so
    /// the real name shows. Call after `load()` + `loadBookableProviders()`.
    func fillProviderNames() {
        guard !bookableProviders.isEmpty else { return }
        let nameById = Dictionary(bookableProviders.map { ($0.id, $0.fullName) },
                                  uniquingKeysWith: { first, _ in first })
        for i in appointments.indices where appointments[i].providerName == nil {
            if let name = nameById[appointments[i].providerId] {
                appointments[i].providerName = name
            }
        }
    }

    /// Client-initiated request: a PREFERRED provider + a primary and backup
    /// time. It stays `requested` (no confirmed time) until a scheduler or the
    /// clinician approves it.
    func requestSession(clientId: UUID, preferredProviderId: UUID, facility: Facility?,
                        type: AppointmentType, purpose: String?,
                        preferredStart: Date, preferredStart2: Date?) async -> Bool {
        let appt = Appointment(
            id: UUID(), clientId: clientId, providerId: preferredProviderId, facility: facility,
            appointmentType: type, purpose: purpose, status: .requested,
            requestedBy: clientId, scheduledStart: nil, durationMinutes: 50,
            requestedProviderId: preferredProviderId,
            preferredStart: preferredStart, preferredStart2: preferredStart2,
            approvedBy: nil,
            zoomMeetingId: nil, zoomJoinUrl: nil, staffNote: nil,
            createdBy: clientId, createdAt: Date(), updatedAt: nil,
            clientName: nil, providerName: nil
        )
        return await persistCreate(appt)
    }

    /// Approve a request: the scheduler keeps or overrides the provider, sets
    /// the final time, and confirms it. Both sides then see it on their schedule.
    func approve(_ appointment: Appointment, providerId: UUID, at start: Date,
                 approvedBy: UUID, videoJoinUrl: String? = nil) async -> Bool {
        var updated = appointment
        updated.providerId = providerId
        updated.scheduledStart = start
        updated.approvedBy = approvedBy
        updated.status = .confirmed
        // Microsoft Teams (BAA-covered) join link the scheduler pasted. Stored
        // in zoomJoinUrl (the generic video-link column); arms the Join button.
        if let link = videoJoinUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty {
            updated.zoomJoinUrl = link
        }
        do {
            _ = try await dataService.updateAppointment(updated)
            // Notify both sides that it's confirmed (PHI-safe: no names).
            await notifyConfirmed(clientId: appointment.clientId, providerId: providerId, at: start)
            // The update response has no embedded names, so reload to bring the
            // client/provider names (and correct ordering) back — otherwise the
            // just-approved card shows a bare "Client".
            await load()
            return true
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.approve")
            errorMessage = "Couldn't approve the session. Try again."
            return false
        }
    }

    /// Fire-and-forget pushes to the client and the assigned provider once a
    /// session is confirmed. Generic wording — nothing identifying travels
    /// through APNs.
    private func notifyConfirmed(clientId: UUID, providerId: UUID, at start: Date) async {
        guard SupabaseConfig.isConfigured else { return }
        let whenStr = start.formatted(date: .abbreviated, time: .shortened)
        await sendUserPush(userId: clientId, title: "Session confirmed",
                           body: "Your session is confirmed for \(whenStr). Open the app for details.")
        await sendUserPush(userId: providerId, title: "New session scheduled",
                           body: "A session is scheduled for \(whenStr). Open the app for details.")
    }

    /// One single-user push. Confirmation notifications are best-effort (the DB
    /// write already succeeded), but a failed send is LOGGED rather than
    /// swallowed so "both sides notified" can't silently mean "neither."
    private func sendUserPush(userId: UUID, title: String, body: String) async {
        do {
            _ = try await SupabaseConfig.client.functions.invoke(
                "send-push-notification",
                options: .init(method: .post, body: AppointmentPushParams(
                    target: "user", userId: userId.uuidString.lowercased(),
                    title: title, body: body))
            )
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.sendUserPush")
        }
    }

    func decline(_ appointment: Appointment) async -> Bool {
        let ok = await updateStatus(appointment, to: .cancelled)
        // Tell the client their request wasn't scheduled — otherwise a declined
        // request just silently turns into a "Cancelled" card they never notice.
        if ok, SupabaseConfig.isConfigured {
            await sendUserPush(userId: appointment.clientId,
                               title: "Session request update",
                               body: "Your session request wasn't scheduled. Open the app or reach out to your care team to find another time.")
        }
        return ok
    }

    /// Staff-initiated scheduling (already confirmed).
    func scheduleSession(clientId: UUID, providerId: UUID, facility: Facility?,
                         type: AppointmentType, purpose: String?, start: Date,
                         durationMinutes: Int, staffNote: String?,
                         videoJoinUrl: String? = nil) async -> Bool {
        let link = videoJoinUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        let appt = Appointment(
            id: UUID(), clientId: clientId, providerId: providerId, facility: facility,
            appointmentType: type, purpose: purpose, status: .confirmed,
            requestedBy: providerId, scheduledStart: start, durationMinutes: durationMinutes,
            zoomMeetingId: nil, zoomJoinUrl: (link?.isEmpty == false) ? link : nil, staffNote: staffNote,
            createdBy: providerId, createdAt: Date(), updatedAt: nil,
            clientName: nil, providerName: nil
        )
        let ok = await persistCreate(appt)
        // A directly-scheduled session is already confirmed — tell the client.
        if ok { await notifyConfirmed(clientId: clientId, providerId: providerId, at: start) }
        return ok
    }

    func updateStatus(_ appointment: Appointment, to status: AppointmentStatus) async -> Bool {
        var updated = appointment
        updated.status = status
        do {
            _ = try await dataService.updateAppointment(updated)
            await load()
            return true
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.updateStatus")
            errorMessage = "Couldn't update the session. Try again."
            return false
        }
    }

    func submitFeedback(appointmentId: UUID, clientId: UUID, rating: Int, reflection: String?) async -> Bool {
        let fb = AppointmentFeedback(
            id: UUID(), appointmentId: appointmentId, clientId: clientId,
            rating: rating, reflection: reflection, createdAt: Date()
        )
        do {
            let saved = try await dataService.submitAppointmentFeedback(fb)
            feedbackByAppointment[appointmentId] = saved
            return true
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.submitFeedback")
            errorMessage = "Couldn't save your feedback. Try again."
            return false
        }
    }

    func loadFeedback(for appointmentId: UUID) async {
        if feedbackByAppointment[appointmentId] != nil { return }
        if let fb = try? await dataService.fetchAppointmentFeedback(appointmentId: appointmentId) {
            feedbackByAppointment[appointmentId] = fb
        }
    }

    // MARK: - Private

    private func persistCreate(_ appt: Appointment) async -> Bool {
        do {
            _ = try await dataService.createAppointment(appt)
            // Reload so the new row comes back with client/provider names
            // resolved, rather than appending a nameless copy.
            await load()
            return true
        } catch {
            CrashReportingService.shared.recordError(error, context: "AppointmentsViewModel.persistCreate")
            errorMessage = "Couldn't schedule the session. Try again."
            return false
        }
    }

    private func replace(_ appt: Appointment) {
        if let i = appointments.firstIndex(where: { $0.id == appt.id }) {
            appointments[i] = appt
        } else {
            appointments.append(appt)
        }
    }
}
