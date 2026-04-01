import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    /// Waits for an unstructured MainActor Task spawned inside a ViewModel to complete.
    /// Sleeps long enough for mock async work, then yields multiple times to drain
    /// any pending MainActor work (e.g., `await MainActor.run { ... }` in the task).
    private func waitForViewModel() async throws {
        try await Task.sleep(for: .milliseconds(1200))
        for _ in 0..<10 { await Task.yield() }
    }

    @Test("loadData populates dailyQuote")
    func loadDataQuote() async throws {
        let vm = HomeViewModel()
        vm.loadData()
        try await waitForViewModel()
        #expect(vm.dailyQuote != nil)
        #expect(!vm.isLoading)
    }

    @Test("loadData populates announcements")
    func loadDataAnnouncements() async throws {
        let vm = HomeViewModel()
        vm.loadData()
        try await waitForViewModel()
        #expect(!vm.announcements.isEmpty)
    }

    @Test("showStrugglingModal defaults to false")
    func strugglingModalDefault() {
        let vm = HomeViewModel()
        #expect(!vm.showStrugglingModal)
    }

    @Test("errorMessage is nil initially")
    func errorMessageDefault() {
        let vm = HomeViewModel()
        #expect(vm.errorMessage == nil)
    }

    @Test("cancelTasks does not crash")
    func cancelTasks() {
        let vm = HomeViewModel()
        vm.loadData()
        vm.cancelTasks()
    }
}
