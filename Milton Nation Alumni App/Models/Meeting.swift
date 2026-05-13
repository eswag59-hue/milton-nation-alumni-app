import Foundation

enum MeetingType: String, Codable, CaseIterable {
    case inPerson = "in_person"
    case virtual
    case hybrid

    var displayName: String {
        switch self {
        case .inPerson: return "In-Person"
        case .virtual: return "Virtual"
        case .hybrid: return "Hybrid"
        }
    }

    var iconName: String {
        switch self {
        case .inPerson: return "mappin.circle.fill"
        case .virtual: return "video.fill"
        case .hybrid: return "person.2.circle.fill"
        }
    }
}

enum RecurrencePattern: String, Codable, CaseIterable {
    case weekly, biweekly, monthly
}

struct Meeting: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var meetingType: MeetingType
    var date: Date
    var startTime: Date
    var endTime: Date
    var locationAddress: String?
    var locationLat: Double?
    var locationLng: Double?
    var virtualLink: String?
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var recurrenceEndDate: Date?
    var parentMeetingId: UUID?
    var createdBy: UUID
    var createdAt: Date
    /// Client-side: populated from the separate `meeting_rsvps` table after fetch.
    /// There is NO `rsvp_user_ids` column on `meetings` — must NOT be in CodingKeys.
    var rsvpUserIds: [UUID] = []

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedTimeRange: String {
        let start = startTime.formatted(date: .omitted, time: .shortened)
        let end = endTime.formatted(date: .omitted, time: .shortened)
        return "\(start) - \(end)"
    }

    // Explicit CodingKeys to exclude `rsvpUserIds` (client-side only — no DB column).
    // Including it would cause decode to throw keyNotFound on every fetch AND make
    // INSERT/UPDATE fail with "column rsvp_user_ids does not exist".
    enum CodingKeys: String, CodingKey {
        case id, title, description, date
        case meetingType        // "meeting_type"
        case startTime          // "start_time"
        case endTime            // "end_time"
        case locationAddress    // "location_address"
        case locationLat        // "location_lat"
        case locationLng        // "location_lng"
        case virtualLink        // "virtual_link"
        case isRecurring        // "is_recurring"
        case recurrencePattern  // "recurrence_pattern"
        case recurrenceEndDate  // "recurrence_end_date"
        case parentMeetingId    // "parent_meeting_id"
        case createdBy          // "created_by"
        case createdAt          // "created_at"
    }
}
