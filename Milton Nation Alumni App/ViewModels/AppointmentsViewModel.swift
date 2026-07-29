import Foundation
import Observation

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

    func loadBookableProviders() async {
        if let list = try? await dataService.fetchBookableProviders() {
            bookableProviders = list
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
                 approvedBy: UUID) async -> Bool {
        var updated = appointment
        updated.providerId = providerId
        updated.scheduledStart = start
        updated.approvedBy = approvedBy
        updated.status = .confirmed
        do {
            _ = try await dataService.updateAppointment(updated)
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

    func decline(_ appointment: Appointment) async -> Bool {
        await updateStatus(appointment, to: .cancelled)
    }

    /// Staff-initiated scheduling (already confirmed).
    func scheduleSession(clientId: UUID, providerId: UUID, facility: Facility?,
                         type: AppointmentType, purpose: String?, start: Date,
                         durationMinutes: Int, staffNote: String?) async -> Bool {
        let appt = Appointment(
            id: UUID(), clientId: clientId, providerId: providerId, facility: facility,
            appointmentType: type, purpose: purpose, status: .confirmed,
            requestedBy: providerId, scheduledStart: start, durationMinutes: durationMinutes,
            zoomMeetingId: nil, zoomJoinUrl: nil, staffNote: staffNote,
            createdBy: providerId, createdAt: Date(), updatedAt: nil,
            clientName: nil, providerName: nil
        )
        return await persistCreate(appt)
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
