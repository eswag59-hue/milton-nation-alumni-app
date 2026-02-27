import Foundation
import CoreLocation

// MARK: - Raw JSON Decoding (all BMLT values are strings)

/// Intermediate struct for decoding the all-strings JSON from the BMLT API.
nonisolated struct BMTLMeetingRaw: Decodable, Sendable {
    let id_bigint: String?
    let meeting_name: String?
    let weekday_tinyint: String?
    let start_time: String?
    let duration_time: String?
    let latitude: String?
    let longitude: String?
    let location_text: String?
    let location_street: String?
    let location_municipality: String?
    let location_province: String?
    let location_postal_code_1: String?
    let formats: String?

    func toBMTLMeeting() -> BMTLMeeting? {
        guard let id = id_bigint,
              let latString = latitude, let lat = Double(latString),
              let lngString = longitude, let lng = Double(lngString) else {
            return nil
        }
        return BMTLMeeting(
            id: id,
            name: meeting_name ?? "Unnamed Meeting",
            weekday: Int(weekday_tinyint ?? "0") ?? 0,
            startTime: start_time ?? "",
            duration: duration_time ?? "",
            latitude: lat,
            longitude: lng,
            locationName: location_text ?? "",
            streetAddress: location_street ?? "",
            city: location_municipality ?? "",
            state: location_province ?? "",
            zip: location_postal_code_1 ?? "",
            formats: formats ?? "",
            distanceMiles: nil
        )
    }
}

// MARK: - Public Model

/// Represents a single meeting from the BMLT root server API.
nonisolated struct BMTLMeeting: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let weekday: Int            // 1=Sunday .. 7=Saturday
    let startTime: String       // "HH:MM:SS"
    let duration: String        // "HH:MM:SS"
    let latitude: Double
    let longitude: Double
    let locationName: String
    let streetAddress: String
    let city: String
    let state: String
    let zip: String
    let formats: String         // e.g. "O,D,12x12"
    var distanceMiles: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var fullAddress: String {
        [streetAddress, city, state, zip]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var weekdayName: String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday",
                     "Thursday", "Friday", "Saturday"]
        guard weekday >= 1, weekday <= 7 else { return "Unknown" }
        return names[weekday - 1]
    }

    var formattedStartTime: String {
        let parts = startTime.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return startTime }
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return startTime }
        return date.formatted(date: .omitted, time: .shortened)
    }

    var formattedDistance: String {
        guard let dist = distanceMiles else { return "" }
        return String(format: "%.1f mi", dist)
    }
}
