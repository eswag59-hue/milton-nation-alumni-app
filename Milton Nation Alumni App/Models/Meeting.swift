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
    var rsvpUserIds: [UUID] = []

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedTimeRange: String {
        let start = startTime.formatted(date: .omitted, time: .shortened)
        let end = endTime.formatted(date: .omitted, time: .shortened)
        return "\(start) - \(end)"
    }
}
