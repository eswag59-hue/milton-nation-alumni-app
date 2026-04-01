import Foundation
import CoreLocation

// MARK: - Fellowship

enum Fellowship: String, Sendable, Hashable {
    case aa = "AA"
    case na = "NA"
}

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

    func toBMTLMeeting(fellowship: Fellowship = .na) -> BMTLMeeting? {
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
            fellowship: fellowship,
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
    let fellowship: Fellowship
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

    /// e.g. "01:00:00" → "1 hour", "01:30:00" → "1h 30m"
    var formattedDuration: String {
        let parts = duration.split(separator: ":").map { String($0) }
        guard parts.count >= 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return "" }
        switch (h, m) {
        case (let h, 0) where h > 0: return "\(h) hour\(h == 1 ? "" : "s")"
        case (0, let m) where m > 0: return "\(m) min"
        case (let h, let m):         return "\(h)h \(m)m"
        }
    }
}

// MARK: - Format Code Decoding

extension BMTLMeeting {
    /// Maps uppercase BMLT format codes to plain-English descriptions.
    static let formatDescriptions: [String: (label: String, detail: String)] = [
        "O":     ("Open",                  "Anyone may attend — you don't need to identify as an addict or alcoholic."),
        "C":     ("Closed",                "For people who want to stop using only. Closed to outside observers."),
        "D":     ("Discussion",            "Open sharing format — anyone present may speak on the topic."),
        "12X12": ("12 Steps & Traditions", "Reads and studies AA or NA's 12 Steps and 12 Traditions texts."),
        "BT":    ("Basic Text",            "Studies NA's Basic Text, the core book of Narcotics Anonymous."),
        "BB":    ("Big Book",              "Studies AA's Big Book, the core text of Alcoholics Anonymous."),
        "CL":    ("Candlelight",           "Meeting is held by candlelight for a quieter, more reflective atmosphere."),
        "SP":    ("Speaker",               "One person shares their personal story of addiction and recovery."),
        "ST":    ("Step Study",            "Focuses on understanding and working one of the 12 steps."),
        "TR":    ("Tradition Study",       "Focuses on one of the 12 traditions that guide the group."),
        "LIT":   ("Literature",            "Reads aloud from approved recovery literature and discusses it."),
        "MED":   ("Meditation",            "Includes a period of quiet meditation or mindfulness."),
        "NS":    ("Non-Smoking",           "This meeting is held in a non-smoking environment."),
        "WC":    ("Wheelchair Accessible", "The meeting location is accessible for wheelchair users."),
        "M":     ("Men Only",              "This meeting is open to men only."),
        "W":     ("Women Only",            "This meeting is open to women only."),
        "YP":    ("Young People",          "Geared toward younger members of the recovery community."),
        "BE":    ("Bilingual",             "Conducted in two languages (English and another language)."),
        "ES":    ("Spanish Speaking",      "Meeting is conducted primarily in Spanish."),
        "H":     ("Hybrid",                "Offered both in-person and online at the same time."),
        "X":     ("Open",                  "Open to all — no restrictions on who may attend."),
        "S":     ("Secular",               "No spiritual or religious component — focuses on the practical steps."),
        "LGBTQ": ("LGBTQ+ Friendly",       "A welcoming space specifically affirming to LGBTQ+ members."),
        "G":     ("Gay",                   "Meeting focused on gay members of the recovery community."),
        "GL":    ("Gay/Lesbian",           "Meeting welcoming to gay and lesbian members."),
        "RF":    ("Refuge Recovery",       "Based on the Refuge Recovery program, a Buddhist-informed approach."),
        "IP":    ("In-Person",             "This meeting takes place at a physical location."),
    ]

    /// Decoded list of (label, detail) pairs for this meeting's format codes.
    var decodedFormats: [(label: String, detail: String)] {
        formats
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap { raw in
                Self.formatDescriptions[raw.uppercased()]
            }
    }
}
