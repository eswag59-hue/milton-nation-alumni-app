import Foundation
import CoreLocation

/// Wraps CLLocationManager for single-shot location requests.
/// Uses `@Observable` for seamless SwiftUI integration.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// Prompts the user for "When In Use" location permission.
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Requests a single GPS fix (battery-friendly).
    func requestCurrentLocation() {
        locationError = nil
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            self.currentLocation = locations.last
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.locationError = error.localizedDescription
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}
