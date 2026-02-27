import SwiftUI

@Observable
final class MeetingsViewModel {
    var meetings: [Meeting] = []
    var isLoading = false
    var selectedMeeting: Meeting?
    var errorMessage: String?

    // MARK: - Filtering & Search
    var searchText = ""
    var selectedTypeFilter: MeetingType?

    var filteredMeetings: [Meeting] {
        var result = meetings

        // Filter by meeting type
        if let typeFilter = selectedTypeFilter {
            result = result.filter { $0.meetingType == typeFilter }
        }

        // Filter by search text
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

    /// RSVP state persisted via UserDefaults.
    var rsvpMeetingIds: Set<UUID> = [] {
        didSet { persistRSVPs() }
    }

    // MARK: - Task Cancellation
    private var loadTask: Task<Void, Never>?

    private let dataService: DataServiceProtocol
    private let cache = OfflineCacheService.shared

    init(dataService: DataServiceProtocol = MockDataService()) {
        self.dataService = dataService
        loadPersistedRSVPs()
    }

    // MARK: - Load Meetings

    func loadMeetings() {
        loadTask?.cancel()
        loadTask = Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                let fetched = try await dataService.fetchMeetings()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    meetings = fetched
                    isLoading = false
                    cache.cacheMeetings(fetched)
                }
            } catch {
                guard !Task.isCancelled else { return }
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

    // MARK: - RSVP Actions

    func toggleRSVP(for meetingId: UUID) {
        if rsvpMeetingIds.contains(meetingId) {
            rsvpMeetingIds.remove(meetingId)
        } else {
            rsvpMeetingIds.insert(meetingId)
        }
    }

    func isRSVPd(meetingId: UUID) -> Bool {
        rsvpMeetingIds.contains(meetingId)
    }

    // MARK: - Filter Actions

    func filterByType(_ type: MeetingType?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTypeFilter = type
        }
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

    // MARK: - RSVP Persistence (UserDefaults)

    private static let rsvpKey = "meeting_rsvp_ids"

    private func persistRSVPs() {
        let strings = rsvpMeetingIds.map(\.uuidString)
        UserDefaults.standard.set(strings, forKey: Self.rsvpKey)
    }

    private func loadPersistedRSVPs() {
        guard let strings = UserDefaults.standard.stringArray(forKey: Self.rsvpKey) else { return }
        rsvpMeetingIds = Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
