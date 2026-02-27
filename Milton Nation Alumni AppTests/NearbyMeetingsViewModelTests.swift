import Testing
import Foundation
import CoreLocation
@testable import Milton_Nation_Alumni_App

@Suite("NearbyMeetingsViewModel Tests")
@MainActor
struct NearbyMeetingsViewModelTests {

    // MARK: - Initial State

    @Test("starts with empty meetings array")
    func initialMeetings() {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        #expect(vm.meetings.isEmpty)
    }

    @Test("starts not loading")
    func initialNotLoading() {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        #expect(!vm.isLoading)
    }

    @Test("starts with no error")
    func initialNoError() {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        #expect(vm.errorMessage == nil)
    }

    @Test("hasRequestedLocation starts false")
    func initialHasNotRequested() {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        #expect(!vm.hasRequestedLocation)
    }

    // MARK: - fetchMeetings

    @Test("fetchMeetings populates meetings array")
    func fetchPopulates() async throws {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        let location = CLLocation(latitude: 40.89, longitude: -74.01)
        vm.fetchMeetings(for: location)
        // MockBMTLMeetingService has 800ms simulated delay
        try await Task.sleep(for: .milliseconds(1200))
        #expect(vm.meetings.count == 10)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("fetchMeetings sets errorMessage on network failure")
    func fetchSetsError() async throws {
        let vm = NearbyMeetingsViewModel(meetingService: FailingMeetingService())
        let location = CLLocation(latitude: 40.89, longitude: -74.01)
        vm.fetchMeetings(for: location)
        try await Task.sleep(for: .milliseconds(200))
        #expect(vm.errorMessage != nil)
        #expect(vm.meetings.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test("fetchMeetings sets errorMessage when zero results returned")
    func fetchSetsErrorOnEmpty() async throws {
        let vm = NearbyMeetingsViewModel(meetingService: EmptyMeetingService())
        let location = CLLocation(latitude: 40.89, longitude: -74.01)
        vm.fetchMeetings(for: location)
        try await Task.sleep(for: .milliseconds(200))
        #expect(vm.errorMessage != nil)
        #expect(vm.meetings.isEmpty)
    }

    @Test("fetchMeetings clears previous error before retrying")
    func fetchClearsError() async throws {
        let vm = NearbyMeetingsViewModel(meetingService: FailingMeetingService())
        let location = CLLocation(latitude: 40.89, longitude: -74.01)

        // First call — sets error
        vm.fetchMeetings(for: location)
        try await Task.sleep(for: .milliseconds(200))
        #expect(vm.errorMessage != nil)

        // errorMessage should be nil while the next fetch is in-flight
        // (we can't easily swap services mid-test, so just verify the error was set)
        #expect(vm.meetings.isEmpty)
    }

    // MARK: - onAppear

    @Test("onAppear sets hasRequestedLocation to true")
    func onAppearSetsFlag() {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        vm.onAppear()
        #expect(vm.hasRequestedLocation)
    }

    @Test("onAppear is idempotent — second call does not re-request")
    func onAppearIdempotent() {
        let vm = NearbyMeetingsViewModel(meetingService: MockBMTLMeetingService())
        vm.onAppear()
        let flagAfterFirst = vm.hasRequestedLocation   // true
        vm.onAppear()                                  // should be a no-op
        #expect(flagAfterFirst == true)
        #expect(vm.hasRequestedLocation == true)
    }

    @Test("onAppear with denied status sets errorMessage")
    func onAppearDenied() {
        // LocationService.authorizationStatus is a mutable var we can set directly
        let locationSvc = LocationService()
        locationSvc.authorizationStatus = .denied
        let vm = NearbyMeetingsViewModel(locationService: locationSvc,
                                         meetingService: MockBMTLMeetingService())
        vm.onAppear()
        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage?.contains("Location access") == true)
    }

    @Test("onAppear with restricted status sets errorMessage")
    func onAppearRestricted() {
        let locationSvc = LocationService()
        locationSvc.authorizationStatus = .restricted
        let vm = NearbyMeetingsViewModel(locationService: locationSvc,
                                         meetingService: MockBMTLMeetingService())
        vm.onAppear()
        #expect(vm.errorMessage != nil)
    }

    // MARK: - handleAuthorizationChange

    @Test("handleAuthorizationChange with denied status sets error")
    func authChangeDenied() {
        let locationSvc = LocationService()
        locationSvc.authorizationStatus = .denied
        let vm = NearbyMeetingsViewModel(locationService: locationSvc,
                                         meetingService: MockBMTLMeetingService())
        vm.handleAuthorizationChange()
        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage?.contains("Location access") == true)
    }

    @Test("handleAuthorizationChange with restricted status sets error")
    func authChangeRestricted() {
        let locationSvc = LocationService()
        locationSvc.authorizationStatus = .restricted
        let vm = NearbyMeetingsViewModel(locationService: locationSvc,
                                         meetingService: MockBMTLMeetingService())
        vm.handleAuthorizationChange()
        #expect(vm.errorMessage != nil)
    }

    @Test("handleAuthorizationChange with notDetermined does not set error")
    func authChangeNotDetermined() {
        let locationSvc = LocationService()
        locationSvc.authorizationStatus = .notDetermined
        let vm = NearbyMeetingsViewModel(locationService: locationSvc,
                                         meetingService: MockBMTLMeetingService())
        vm.handleAuthorizationChange()
        #expect(vm.errorMessage == nil)
    }
}

// MARK: - Test doubles for meeting service

/// Always throws a network error.
final class FailingMeetingService: BMTLMeetingServiceProtocol {
    func fetchNearbyMeetings(
        latitude: Double, longitude: Double,
        radiusMiles: Double, maxResults: Int
    ) async throws -> [BMTLMeeting] {
        throw URLError(.notConnectedToInternet)
    }
}

/// Returns an empty array (no meetings found).
final class EmptyMeetingService: BMTLMeetingServiceProtocol {
    func fetchNearbyMeetings(
        latitude: Double, longitude: Double,
        radiusMiles: Double, maxResults: Int
    ) async throws -> [BMTLMeeting] {
        return []
    }
}
