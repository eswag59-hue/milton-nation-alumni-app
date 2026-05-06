import Foundation
import CoreLocation

// MARK: - Protocol

protocol BMTLMeetingServiceProtocol: Sendable {
    func fetchNearbyMeetings(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double,
        maxResults: Int
    ) async throws -> [BMTLMeeting]
}

// MARK: - In-Person Filter

/// BMLT format codes that indicate a meeting has no physical location.
private let virtualFormatCodes: Set<String> = ["VM", "ONL", "ZOOM", "TC"]

private func isInPerson(formats: String) -> Bool {
    let codes = formats.uppercased()
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
    return !codes.contains { virtualFormatCodes.contains($0) }
}

// MARK: - Shared BMLT Fetcher

/// Handles the common fetch-decode-filter-sort logic for any BMLT root server.
private struct BMTLMeetingFetcher: Sendable {
    let baseURL: String
    let fellowship: Fellowship
    private let session: URLSession

    init(baseURL: String, fellowship: Fellowship, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.fellowship = fellowship
        self.session = session
    }

    func fetch(latitude: Double, longitude: Double, radiusMiles: Double) async throws -> [BMTLMeeting] {
        guard var components = URLComponents(string: baseURL) else {
            throw BMTLError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "switcher", value: "GetSearchResults"),
            URLQueryItem(name: "lat_val", value: String(latitude)),
            URLQueryItem(name: "long_val", value: String(longitude)),
            URLQueryItem(name: "geo_width", value: String(radiusMiles)),
            URLQueryItem(name: "sort_results_by_distance", value: "1"),
        ]
        guard let url = components.url else { throw BMTLError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw BMTLError.serverError
        }

        let raw = try JSONDecoder().decode([BMTLMeetingRaw].self, from: data)
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)

        var meetings = raw
            .compactMap { $0.toBMTLMeeting(fellowship: fellowship) }
            .filter { isInPerson(formats: $0.formats) }

        for i in meetings.indices {
            let loc = CLLocation(latitude: meetings[i].latitude, longitude: meetings[i].longitude)
            meetings[i].distanceMiles = userLocation.distance(from: loc) / 1609.344
        }

        return meetings
    }
}

// MARK: - NA Production Service

/// Fetches in-person NA meetings from the worldwide BMLT Tomato aggregator.
/// This is the official BMLT aggregation server (aggregator.bmltenabled.org) used by the
/// NAWS iOS/Android apps. It aggregates 42 root servers worldwide and covers the entire
/// United States — results always reflect the lat/lng passed in, not a fixed location.
///
/// The former na.org and aa.org endpoints both returned 404 after NAWS migrated in 2024.
/// AA World Services has no equivalent public JSON API; NA's aggregator is the correct
/// production endpoint for both fellowship types.
final class NABMTLMeetingService: BMTLMeetingServiceProtocol {
    private let fetcher: BMTLMeetingFetcher

    init(session: URLSession = .shared) {
        self.fetcher = BMTLMeetingFetcher(
            baseURL: "https://aggregator.bmltenabled.org/main_server/client_interface/json/",
            fellowship: .na,
            session: session
        )
    }

    func fetchNearbyMeetings(
        latitude: Double, longitude: Double,
        radiusMiles: Double = 10, maxResults: Int = 10
    ) async throws -> [BMTLMeeting] {
        try await fetcher.fetch(latitude: latitude, longitude: longitude, radiusMiles: radiusMiles)
    }
}

// MARK: - Combined Service (NA aggregator — worldwide coverage)

/// Wraps the NA BMLT aggregator. The former AA endpoint (aa.org) never existed as a BMLT
/// root server and AA World Services has no equivalent public JSON API, so this service
/// uses the worldwide NA aggregator as the single authoritative source.
/// Results are always sorted by distance from the device's actual location.
final class CombinedNearbyMeetingService: BMTLMeetingServiceProtocol {
    private let naService: NABMTLMeetingService

    init() {
        self.naService = NABMTLMeetingService()
    }

    func fetchNearbyMeetings(
        latitude: Double, longitude: Double,
        radiusMiles: Double = 10, maxResults: Int = 10
    ) async throws -> [BMTLMeeting] {
        let meetings = try await naService.fetchNearbyMeetings(
            latitude: latitude, longitude: longitude,
            radiusMiles: radiusMiles, maxResults: maxResults
        )

        if meetings.isEmpty {
            throw BMTLError.noResults
        }

        return Array(meetings.prefix(maxResults))
    }
}

// MARK: - Mock (simulator / tests)

/// Returns mixed AA + NA in-person meetings for development and testing.
final class MockBMTLMeetingService: BMTLMeetingServiceProtocol {
    /// Returns canned meetings only when an XCTest run is detected — otherwise
    /// returns an empty list. This prevents fake "Miami" meetings from polluting
    /// the simulator UI when developers forget they're in DEBUG mode.
    func fetchNearbyMeetings(
        latitude: Double, longitude: Double,
        radiusMiles: Double = 10, maxResults: Int = 10
    ) async throws -> [BMTLMeeting] {
        try await Task.sleep(for: .milliseconds(800))
        // Only return canned data inside the XCTest harness
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return Array(mockMeetings.prefix(maxResults))
        }
        return []
    }

    private let mockMeetings: [BMTLMeeting] = [
        BMTLMeeting(id: "1001", name: "Serenity Now Group", weekday: 2, startTime: "19:00:00", duration: "01:00:00", latitude: 25.7650, longitude: -80.1936, locationName: "Community Center", streetAddress: "100 NE 1st Ave", city: "Miami", state: "FL", zip: "33132", formats: "O,D", fellowship: .na, distanceMiles: 0.4),
        BMTLMeeting(id: "1002", name: "New Beginnings", weekday: 4, startTime: "12:00:00", duration: "01:00:00", latitude: 25.7700, longitude: -80.1950, locationName: "Unity Church", streetAddress: "200 Biscayne Blvd", city: "Miami", state: "FL", zip: "33131", formats: "O,12x12", fellowship: .aa, distanceMiles: 1.2),
        BMTLMeeting(id: "1003", name: "One Day at a Time", weekday: 1, startTime: "09:00:00", duration: "01:30:00", latitude: 25.7580, longitude: -80.2000, locationName: "Fellowship Hall", streetAddress: "350 SW 2nd St", city: "Miami", state: "FL", zip: "33130", formats: "O,D,CL", fellowship: .na, distanceMiles: 1.8),
        BMTLMeeting(id: "1004", name: "Hope & Healing", weekday: 3, startTime: "18:30:00", duration: "01:00:00", latitude: 25.7550, longitude: -80.2100, locationName: "Grace Methodist", streetAddress: "500 Coral Way", city: "Miami", state: "FL", zip: "33134", formats: "C,D", fellowship: .aa, distanceMiles: 2.5),
        BMTLMeeting(id: "1005", name: "Living Sober", weekday: 6, startTime: "10:00:00", duration: "01:00:00", latitude: 25.7800, longitude: -80.2200, locationName: "Veterans Hall", streetAddress: "800 NW 7th Ave", city: "Miami", state: "FL", zip: "33136", formats: "O,D,12x12", fellowship: .na, distanceMiles: 3.1),
        BMTLMeeting(id: "1006", name: "Easy Does It", weekday: 5, startTime: "20:00:00", duration: "01:00:00", latitude: 25.7620, longitude: -80.2050, locationName: "St. Patrick's Parish", streetAddress: "620 SW 3rd Ave", city: "Miami", state: "FL", zip: "33130", formats: "O,D", fellowship: .aa, distanceMiles: 3.6),
        BMTLMeeting(id: "1007", name: "Sunrise Sobriety", weekday: 1, startTime: "07:00:00", duration: "01:00:00", latitude: 25.7850, longitude: -80.1870, locationName: "Bayfront Park Pavilion", streetAddress: "301 Biscayne Blvd", city: "Miami", state: "FL", zip: "33132", formats: "O,CL", fellowship: .na, distanceMiles: 4.0),
        BMTLMeeting(id: "1008", name: "Keep It Simple", weekday: 7, startTime: "17:00:00", duration: "01:30:00", latitude: 25.7500, longitude: -80.2300, locationName: "Shenandoah Community", streetAddress: "1400 SW 22nd St", city: "Miami", state: "FL", zip: "33145", formats: "C,D,12x12", fellowship: .aa, distanceMiles: 4.8),
        BMTLMeeting(id: "1009", name: "Freedom Group", weekday: 2, startTime: "12:00:00", duration: "01:00:00", latitude: 25.7900, longitude: -80.2100, locationName: "Allapattah Recreation", streetAddress: "1550 NW 12th Ave", city: "Miami", state: "FL", zip: "33136", formats: "O,D", fellowship: .na, distanceMiles: 5.2),
        BMTLMeeting(id: "1010", name: "Courage to Change", weekday: 4, startTime: "19:30:00", duration: "01:00:00", latitude: 25.7450, longitude: -80.2400, locationName: "Coral Gables Congregational", streetAddress: "3010 De Soto Blvd", city: "Coral Gables", state: "FL", zip: "33134", formats: "O,D,CL", fellowship: .aa, distanceMiles: 5.9),
    ]
}

// MARK: - Errors

enum BMTLError: LocalizedError {
    case invalidURL
    case serverError
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid BMLT API URL"
        case .serverError: return "Unable to reach the meeting server. Please try again."
        case .noResults: return "No in-person meetings found within 10 miles."
        }
    }
}
