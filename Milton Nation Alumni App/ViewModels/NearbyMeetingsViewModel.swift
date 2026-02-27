import SwiftUI
import CoreLocation

@Observable
final class NearbyMeetingsViewModel {
    var meetings: [BMTLMeeting] = []
    var isLoading = false
    var errorMessage: String?
    var hasRequestedLocation = false

    let locationService: LocationService
    private let meetingService: BMTLMeetingServiceProtocol
    private let radiusMiles: Double = 10
    private let maxResults: Int = 10

    init(locationService: LocationService = LocationService(),
         meetingService: BMTLMeetingServiceProtocol? = nil) {
        self.locationService = locationService
        // On simulator: use mock data so the page always loads without GPS.
        // On real device: use live BMLT API.
        #if targetEnvironment(simulator)
        self.meetingService = meetingService ?? MockBMTLMeetingService()
        #else
        self.meetingService = meetingService ?? BMTLMeetingService()
        #endif
    }

    // MARK: - Lifecycle

    /// Called when the Nearby tab appears for the first time.
    func onAppear() {
        guard !hasRequestedLocation else { return }
        hasRequestedLocation = true

        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestLocationPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            locationService.requestCurrentLocation()
        case .denied, .restricted:
            errorMessage = "Location access is required to find nearby meetings. Please enable it in Settings > Privacy > Location Services."
        @unknown default:
            break
        }
    }

    // MARK: - Fetch

    /// Fetches meetings from the BMLT API using the given location.
    func fetchMeetings(for location: CLLocation) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                meetings = try await meetingService.fetchNearbyMeetings(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    radiusMiles: radiusMiles,
                    maxResults: maxResults
                )
                if meetings.isEmpty {
                    errorMessage = "No support meetings found within \(Int(radiusMiles)) miles."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Authorization Changes

    /// Responds to location permission changes.
    func handleAuthorizationChange() {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if locationService.currentLocation == nil {
                locationService.requestCurrentLocation()
            }
        case .denied, .restricted:
            errorMessage = "Location access is required to find nearby meetings. Please enable it in Settings > Privacy > Location Services."
        default:
            break
        }
    }
}
