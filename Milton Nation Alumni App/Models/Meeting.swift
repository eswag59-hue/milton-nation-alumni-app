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
    /// Which facility this meeting belongs to. `nil` means BOTH facilities —
    /// used for shared virtual meetings. Server-side RLS enforces the same rule,
    /// so this is a display/authoring concern, not the security boundary.
    var facility: Facility? = nil
    /// Client-side: populated from the separate `meeting_rsvps` table after fetch.
    /// There is NO `rsvp_user_ids` column on `meetings` — must NOT be in CodingKeys.
    var rsvpUserIds: [UUID] = []

    /// The date this meeting next takes place.
    ///
    /// `date` stores the series *anchor* — the first occurrence — so a weekly
    /// meeting created in May still reports May forever. Displaying that told
    /// members a meeting had already happened when it recurs every week.
    var nextOccurrence: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard isRecurring, let pattern = recurrencePattern, date < today else { return date }

        let step: DateComponents
        switch pattern {
        case .weekly:   step = DateComponents(day: 7)
        case .biweekly: step = DateComponents(day: 14)
        case .monthly:  step = DateComponents(month: 1)
        }

        // Bounded walk forward — a corrupt anchor date must not spin forever.
        var candidate = date
        var iterations = 0
        while candidate < today, iterations < 600 {
            guard let next = cal.date(byAdding: step, to: candidate) else { break }
            candidate = next
            iterations += 1
        }
        if let end = recurrenceEndDate, candidate > end { return date }
        return candidate
    }

    /// True once a meeting can no longer occur: a one-off whose date has passed,
    /// or a recurring series past its end date.
    var isExpired: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if isRecurring {
            guard let end = recurrenceEndDate else { return false }
            return end < today
        }
        return date < today
    }

    var formattedDate: String {
        nextOccurrence.formatted(date: .abbreviated, time: .omitted)
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
        case facility
    }
}
