import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("MeetingsViewModel Tests")
struct MeetingsViewModelTests {

    /// Waits for an unstructured MainActor Task spawned inside a ViewModel to complete.
    private func waitForViewModel(ms: Int = 1200) async throws {
        try await Task.sleep(for: .milliseconds(ms))
        for _ in 0..<10 { await Task.yield() }
    }

    // MARK: - Loading

    @Test("loadMeetings populates meetings array")
    func loadMeetings() async throws {
        let vm = MeetingsViewModel(meetingService: MockMeetingService())
        vm.loadMeetings()
        // Wait for async task
        try await waitForViewModel()
        #expect(!vm.meetings.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test("loadMeetings sets isLoading to false after completion")
    func loadMeetingsFinishesLoading() async throws {
        let vm = MeetingsViewModel(meetingService: MockMeetingService())
        vm.loadMeetings()
        try await waitForViewModel()
        #expect(vm.isLoading == false)
    }

    // MARK: - RSVP

    @Test("toggleRSVP adds meeting ID to rsvpMeetingIds")
    func toggleRSVPAdd() {
        let vm = MeetingsViewModel()
        let meetingId = UUID()
        vm.toggleRSVP(for: meetingId)
        #expect(vm.rsvpMeetingIds.contains(meetingId))
    }

    @Test("toggleRSVP removes meeting ID when already RSVPd")
    func toggleRSVPRemove() {
        let vm = MeetingsViewModel()
        let meetingId = UUID()
        vm.toggleRSVP(for: meetingId)
        vm.toggleRSVP(for: meetingId)
        #expect(!vm.rsvpMeetingIds.contains(meetingId))
    }

    @Test("isRSVPd returns correct value")
    func isRSVPd() {
        let vm = MeetingsViewModel()
        let meetingId = UUID()
        #expect(!vm.isRSVPd(meetingId: meetingId))
        vm.toggleRSVP(for: meetingId)
        #expect(vm.isRSVPd(meetingId: meetingId))
    }

    // MARK: - Filtering

    @Test("filteredMeetings returns all meetings when no filter")
    func filteredNoFilter() async throws {
        let vm = MeetingsViewModel(meetingService: MockMeetingService())
        vm.loadMeetings()
        try await waitForViewModel()
        #expect(vm.filteredMeetings.count == vm.meetings.count)
    }

    @Test("filterByType sets the selectedTypeFilter")
    func filterByType() {
        let vm = MeetingsViewModel()
        vm.filterByType(.virtual)
        #expect(vm.selectedTypeFilter == .virtual)
    }

    @Test("clearFilters resets search and type filter")
    func clearFilters() {
        let vm = MeetingsViewModel()
        vm.searchText = "test"
        vm.filterByType(.inPerson)
        vm.clearFilters()
        #expect(vm.searchText.isEmpty)
        #expect(vm.selectedTypeFilter == nil)
    }

    @Test("filteredMeetings filters by search text")
    func filterBySearch() async throws {
        let vm = MeetingsViewModel(meetingService: MockMeetingService())
        vm.loadMeetings()
        try await waitForViewModel()
        guard !vm.meetings.isEmpty else { return }
        let firstTitle = vm.meetings[0].title
        vm.searchText = firstTitle
        #expect(!vm.filteredMeetings.isEmpty)
        #expect(vm.filteredMeetings.allSatisfy {
            $0.title.localizedCaseInsensitiveContains(firstTitle)
        })
    }

    // MARK: - Cancellation

    @Test("cancelTasks does not crash")
    func cancelTasks() {
        let vm = MeetingsViewModel(meetingService: MockMeetingService())
        vm.loadMeetings()
        vm.cancelTasks() // Should not crash
    }
}
