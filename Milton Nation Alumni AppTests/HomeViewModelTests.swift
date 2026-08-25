import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    /// Polls until `cond` holds (or the deadline passes) — fixed sleeps raced the
    /// ViewModel's unstructured Tasks on slow shared CI simulators.
    private func waitUntil(timeout: Double = 10, _ cond: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !cond() && Date() < deadline {
            try await Task.sleep(for: .milliseconds(80))
            await Task.yield()
        }
    }

    @Test("loadData populates dailyQuote")
    func loadDataQuote() async throws {
        let vm = HomeViewModel()
        vm.loadData()
        try await waitUntil { vm.dailyQuote != nil && !vm.isLoading }
        #expect(vm.dailyQuote != nil)
        #expect(!vm.isLoading)
    }

    @Test("loadData populates announcements")
    func loadDataAnnouncements() async throws {
        let vm = HomeViewModel()
        vm.loadData()
        try await waitUntil { !vm.announcements.isEmpty }
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
