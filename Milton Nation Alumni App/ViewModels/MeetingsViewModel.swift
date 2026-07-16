import SwiftUI

@Observable
final class MeetingsViewModel {
    var meetings: [Meeting] = []
    var isLoading = false
    var isSaving = false
    var selectedMeeting: Meeting?
    var errorMessage: String?

    // MARK: - Filtering & Search

    var searchText = ""
    var selectedTypeFilter: MeetingType?

    var filteredMeetings: [Meeting] {
        var result = meetings
        if let typeFilter = selectedTypeFilter {
            result = result.filter { $0.meetingType == typeFilter }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.locationAddress?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return result
    }

    // MARK: - RSVP

    var rsvpMeetingIds: Set<UUID> = [] {
        didSet { persistRSVPs() }
    }

    // MARK: - Dependencies

    private var loadTask: Task<Void, Never>?
    private let meetingService: MeetingServiceProtocol
    private let cache = OfflineCacheService.shared

    init(meetingService: MeetingServiceProtocol = {
        #if DEBUG
        return MockMeetingService()
        #else
        return SupabaseMeetingService()
        #endif
    }()) {
        self.meetingService = meetingService
        loadPersistedRSVPs()
    }

    // MARK: - Load

    func loadMeetings() {
        loadTask?.cancel()
        loadTask = Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                let fetched = try await meetingService.fetchMeetings()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    meetings = fetched
                    isLoading = false
                    cache.cacheMeetings(fetched)
                }
                loadRSVPs()   // refresh RSVPs from the server alongside meetings
            } catch {
                guard !Task.isCancelled else { return }
                CrashReportingService.shared.recordError(error, context: "MeetingsViewModel.fetchMeetings")
                await MainActor.run {
                    if let cached = cache.loadCachedMeetings() {
                        meetings = cached
                        errorMessage = nil
                    } else {
                        errorMessage = "Unable to load meetings. Please check your connection and try again."
                    }
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Admin: Create

    func createMeeting(_ meeting: Meeting) async {
        await MainActor.run { isSaving = true; errorMessage = nil }
        do {
            let created = try await meetingService.createMeeting(meeting)
            await MainActor.run {
                meetings.append(created)
                meetings.sort { $0.startTime < $1.startTime }
                isSaving = false
            }
        } catch {
            CrashReportingService.shared.recordError(error, context: "MeetingsViewModel.createMeeting")
            await MainActor.run {
                errorMessage = "Failed to create meeting: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }

    // MARK: - Admin: Update

    func updateMeeting(_ meeting: Meeting) async {
        await MainActor.run { isSaving = true; errorMessage = nil }
        do {
            let updated = try await meetingService.updateMeeting(meeting)
            await MainActor.run {
                if let idx = meetings.firstIndex(where: { $0.id == updated.id }) {
                    meetings[idx] = updated
                }
                meetings.sort { $0.startTime < $1.startTime }
                isSaving = false
            }
        } catch {
            CrashReportingService.shared.recordError(error, context: "MeetingsViewModel.updateMeeting")
            await MainActor.run {
                errorMessage = "Failed to update meeting: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }

    // MARK: - Admin: Delete

    func deleteMeeting(meetingId: UUID) async {
        await MainActor.run { isSaving = true; errorMessage = nil }
        do {
            try await meetingService.deleteMeeting(meetingId: meetingId)
            await MainActor.run {
                meetings.removeAll { $0.id == meetingId }
                isSaving = false
            }
        } catch {
            CrashReportingService.shared.recordError(error, context: "MeetingsViewModel.deleteMeeting")
            await MainActor.run {
                errorMessage = "Failed to delete meeting: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }

    // MARK: - RSVP

    func toggleRSVP(for meetingId: UUID) {
        let willAttend = !rsvpMeetingIds.contains(meetingId)
        // Optimistic UI (also caches to UserDefaults via didSet for offline).
        if willAttend { rsvpMeetingIds.insert(meetingId) } else { rsvpMeetingIds.remove(meetingId) }
        // Persist to the server (meeting_rsvps). Roll back on failure.
        Task {
            do {
                try await meetingService.setRSVP(meetingId: meetingId, attending: willAttend)
            } catch {
                CrashReportingService.shared.recordError(error, context: "MeetingsViewModel.toggleRSVP")
                await MainActor.run {
                    if willAttend { rsvpMeetingIds.remove(meetingId) } else { rsvpMeetingIds.insert(meetingId) }
                    errorMessage = "Couldn't save your RSVP. Please try again."
                }
            }
        }
    }

    /// Load the user's RSVPs from the server so they persist across launches
    /// and devices. Falls back silently to the UserDefaults cache on failure.
    func loadRSVPs() {
        Task {
            do {
                let server = try await meetingService.fetchMyRSVPs()
                await MainActor.run { rsvpMeetingIds = server }
            } catch {
                // Keep the locally-cached set; not worth surfacing an error.
                CrashReportingService.shared.recordError(error, context: "MeetingsViewModel.loadRSVPs")
            }
        }
    }

    func isRSVPd(meetingId: UUID) -> Bool {
        rsvpMeetingIds.contains(meetingId)
    }

    // MARK: - Filters

    func filterByType(_ type: MeetingType?) {
        withAnimation(.easeInOut(duration: 0.2)) { selectedTypeFilter = type }
    }

    func clearFilters() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTypeFilter = nil
            searchText = ""
        }
    }

    // MARK: - Cleanup

    func cancelTasks() {
        loadTask?.cancel()
        loadTask = nil
    }

    // MARK: - RSVP Persistence

    private static let rsvpKey = "meeting_rsvp_ids"

    private func persistRSVPs() {
        UserDefaults.standard.set(rsvpMeetingIds.map(\.uuidString), forKey: Self.rsvpKey)
    }

    private func loadPersistedRSVPs() {
        guard let strings = UserDefaults.standard.stringArray(forKey: Self.rsvpKey) else { return }
        rsvpMeetingIds = Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
