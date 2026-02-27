import Foundation
import CoreLocation

// MARK: - Protocol (enables mock/test implementations)

/// Abstract interface for fetching BMLT meetings.
/// Designed to be extractable to AWS Lambda — no CLLocationManager dependency.
protocol BMTLMeetingServiceProtocol: Sendable {
    func fetchNearbyMeetings(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double,
        maxResults: Int
    ) async throws -> [BMTLMeeting]
}

// MARK: - Production Implementation

/// Fetches real meeting data from the BMLT root server via URLSession.
/// Zero dependency on CLLocationManager — only uses CLLocation for distance math.
final class BMTLMeetingService: BMTLMeetingServiceProtocol {

    private let session: URLSession
    private let baseURL: String

    init(session: URLSession = .shared,
         baseURL: String = "https://tomato.bmltenabled.org/main_server/client_interface/json/") {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchNearbyMeetings(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double = 10,
        maxResults: Int = 10
    ) async throws -> [BMTLMeeting] {
        // 1. Build URL with BMLT query parameters
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

        guard let url = components.url else {
            throw BMTLError.invalidURL
        }

        // 2. Fetch from BMLT server
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BMTLError.serverError
        }

        // 3. Decode all-strings JSON via intermediate struct
        let rawMeetings = try JSONDecoder().decode([BMTLMeetingRaw].self, from: data)

        // 4. Convert, calculate distances, sort, and take top N
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        var meetings = rawMeetings.compactMap { $0.toBMTLMeeting() }

        for i in meetings.indices {
            let meetingLocation = CLLocation(
                latitude: meetings[i].latitude,
                longitude: meetings[i].longitude
            )
            // Convert meters to miles
            meetings[i].distanceMiles = userLocation.distance(from: meetingLocation) / 1609.344
        }

        meetings.sort { ($0.distanceMiles ?? .infinity) < ($1.distanceMiles ?? .infinity) }

        return Array(meetings.prefix(maxResults))
    }
}

// MARK: - Mock Implementation (for DEBUG / previews / tests)

/// Returns 10 hardcoded Miami-area meetings for development and testing.
final class MockBMTLMeetingService: BMTLMeetingServiceProtocol {
    func fetchNearbyMeetings(
        latitude: Double,
        longitude: Double,
        radiusMiles: Double = 10,
        maxResults: Int = 10
    ) async throws -> [BMTLMeeting] {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))

        let allMeetings = [
            BMTLMeeting(
                id: "1001", name: "Serenity Now Group",
                weekday: 2, startTime: "19:00:00", duration: "01:00:00",
                latitude: 25.7650, longitude: -80.1936,
                locationName: "Community Center", streetAddress: "100 NE 1st Ave",
                city: "Miami", state: "FL", zip: "33132",
                formats: "O,D", distanceMiles: 0.4
            ),
            BMTLMeeting(
                id: "1002", name: "New Beginnings",
                weekday: 4, startTime: "12:00:00", duration: "01:00:00",
                latitude: 25.7700, longitude: -80.1950,
                locationName: "Unity Church", streetAddress: "200 Biscayne Blvd",
                city: "Miami", state: "FL", zip: "33131",
                formats: "O,12x12", distanceMiles: 1.2
            ),
            BMTLMeeting(
                id: "1003", name: "One Day at a Time",
                weekday: 1, startTime: "09:00:00", duration: "01:30:00",
                latitude: 25.7580, longitude: -80.2000,
                locationName: "Fellowship Hall", streetAddress: "350 SW 2nd St",
                city: "Miami", state: "FL", zip: "33130",
                formats: "O,D,CL", distanceMiles: 1.8
            ),
            BMTLMeeting(
                id: "1004", name: "Hope & Healing",
                weekday: 3, startTime: "18:30:00", duration: "01:00:00",
                latitude: 25.7550, longitude: -80.2100,
                locationName: "Grace Methodist", streetAddress: "500 Coral Way",
                city: "Miami", state: "FL", zip: "33134",
                formats: "C,D", distanceMiles: 2.5
            ),
            BMTLMeeting(
                id: "1005", name: "Living Sober",
                weekday: 6, startTime: "10:00:00", duration: "01:00:00",
                latitude: 25.7800, longitude: -80.2200,
                locationName: "Veterans Hall", streetAddress: "800 NW 7th Ave",
                city: "Miami", state: "FL", zip: "33136",
                formats: "O,D,12x12", distanceMiles: 3.1
            ),
            BMTLMeeting(
                id: "1006", name: "Easy Does It",
                weekday: 5, startTime: "20:00:00", duration: "01:00:00",
                latitude: 25.7620, longitude: -80.2050,
                locationName: "St. Patrick's Parish", streetAddress: "620 SW 3rd Ave",
                city: "Miami", state: "FL", zip: "33130",
                formats: "O,D", distanceMiles: 3.6
            ),
            BMTLMeeting(
                id: "1007", name: "Sunrise Sobriety",
                weekday: 1, startTime: "07:00:00", duration: "01:00:00",
                latitude: 25.7850, longitude: -80.1870,
                locationName: "Bayfront Park Pavilion", streetAddress: "301 Biscayne Blvd",
                city: "Miami", state: "FL", zip: "33132",
                formats: "O,CL", distanceMiles: 4.0
            ),
            BMTLMeeting(
                id: "1008", name: "Keep It Simple",
                weekday: 7, startTime: "17:00:00", duration: "01:30:00",
                latitude: 25.7500, longitude: -80.2300,
                locationName: "Shenandoah Community", streetAddress: "1400 SW 22nd St",
                city: "Miami", state: "FL", zip: "33145",
                formats: "C,D,12x12", distanceMiles: 4.8
            ),
            BMTLMeeting(
                id: "1009", name: "Freedom Group",
                weekday: 2, startTime: "12:00:00", duration: "01:00:00",
                latitude: 25.7900, longitude: -80.2100,
                locationName: "Allapattah Recreation", streetAddress: "1550 NW 12th Ave",
                city: "Miami", state: "FL", zip: "33136",
                formats: "O,D", distanceMiles: 5.2
            ),
            BMTLMeeting(
                id: "1010", name: "Courage to Change",
                weekday: 4, startTime: "19:30:00", duration: "01:00:00",
                latitude: 25.7450, longitude: -80.2400,
                locationName: "Coral Gables Congregational", streetAddress: "3010 De Soto Blvd",
                city: "Coral Gables", state: "FL", zip: "33134",
                formats: "O,D,CL", distanceMiles: 5.9
            ),
        ]

        return Array(allMeetings.prefix(maxResults))
    }
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
        case .noResults: return "No meetings found in your area"
        }
    }
}
