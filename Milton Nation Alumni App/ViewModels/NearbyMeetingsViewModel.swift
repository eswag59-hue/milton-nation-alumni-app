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
        // Always use the live BMLT API so meetings reflect the device's actual location.
        // The BMLT directory is worldwide — it returns real meetings near any coordinates,
        // including simulator locations (e.g. California) and real devices (e.g. New Jersey).
        // In unit tests: pass a MockBMTLMeetingService explicitly via the meetingService param.
        self.meetingService = meetingService ?? CombinedNearbyMeetingService()
    }

    // MARK: - Lifecycle

    /// Called when the Nearby tab appears.
    func onAppear() {
        guard !hasRequestedLocation else { return }
        hasRequestedLocation = true

        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestLocationPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            // If we already have a location, fetch right away.
            // requestCurrentLocation() may return the same coordinate → onChange
            // won't fire (value didn't change) → meetings would never load.
            if let existing = locationService.currentLocation {
                fetchMeetings(for: existing)
            }
            // Always ask for a fresh fix so the map stays current.
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
                CrashReportingService.shared.recordError(error, context: "NearbyMeetingsViewModel.fetchNearbyMeetings")
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
