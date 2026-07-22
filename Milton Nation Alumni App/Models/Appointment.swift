import Foundation

/// A scheduled 1:1 telehealth session between a client and a provider.
///
/// Distinct from `Meeting` (open alumni / AA-NA groups). An appointment is
/// private care: facility-scoped, delivered over a per-session video link,
/// and visible only to its client, its provider, and that facility's staff.
enum AppointmentType: String, Codable, CaseIterable, Identifiable {
    case individualTherapy = "individual_therapy"
    case groupTherapy      = "group_therapy"
    case psychiatry        = "psychiatry"
    case caseManagement    = "case_management"
    case intake            = "intake"
    case familySession     = "family_session"
    case checkIn           = "check_in"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .individualTherapy: return "Individual Therapy"
        case .groupTherapy:      return "Group Therapy"
        case .psychiatry:        return "Psychiatry"
        case .caseManagement:    return "Case Management"
        case .intake:            return "Intake"
        case .familySession:     return "Family Session"
        case .checkIn:           return "Check-In"
        }
    }

    var icon: String {
        switch self {
        case .individualTherapy: return "person.fill"
        case .groupTherapy:      return "person.3.fill"
        case .psychiatry:        return "brain.head.profile"
        case .caseManagement:    return "folder.fill"
        case .intake:            return "doc.text.fill"
        case .familySession:     return "figure.2.and.child.holdinghands"
        case .checkIn:           return "checkmark.circle.fill"
        }
    }
}

enum AppointmentStatus: String, Codable {
    case requested
    case confirmed
    case cancelled
    case completed
    case noShow = "no_show"

    var displayName: String {
        switch self {
        case .requested: return "Requested"
        case .confirmed: return "Confirmed"
        case .cancelled: return "Cancelled"
        case .completed: return "Completed"
        case .noShow:    return "No-Show"
        }
    }
}

struct Appointment: Identifiable, Codable {
    let id: UUID
    var clientId: UUID
    var providerId: UUID
    var facility: Facility?
    var appointmentType: AppointmentType
    var purpose: String?
    var status: AppointmentStatus
    var requestedBy: UUID?
    var scheduledStart: Date?
    var durationMinutes: Int
    /// Who the client originally asked for (immutable). `providerId` is who's
    /// actually assigned — the approver may override it.
    var requestedProviderId: UUID? = nil
    /// The client's primary and backup preferred times (requests only).
    var preferredStart: Date? = nil
    var preferredStart2: Date? = nil
    /// The scheduler/clinician who approved the request.
    var approvedBy: UUID? = nil
    var zoomMeetingId: String?
    var zoomJoinUrl: String?
    var staffNote: String?
    var createdBy: UUID?
    var createdAt: Date
    var updatedAt: Date?

    /// Client-side enrichment, joined after fetch from the roster. Not columns —
    /// must be excluded from CodingKeys or every decode throws keyNotFound.
    var clientName: String?
    var providerName: String?

    // camelCase cases + the shared decoder's .convertFromSnakeCase map
    // "client_id" → "clientId", etc. Explicit snake_case strings here would
    // double-map and break decoding. clientName/providerName are omitted so
    // they aren't sought in the row.
    enum CodingKeys: String, CodingKey {
        case id, facility, purpose, status
        case clientId
        case providerId
        case appointmentType
        case requestedBy
        case scheduledStart
        case durationMinutes
        case zoomMeetingId
        case zoomJoinUrl
        case staffNote
        case createdBy
        case createdAt
        case updatedAt
        case requestedProviderId
        case preferredStart
        case preferredStart2
        case approvedBy
    }

    var scheduledEnd: Date? {
        scheduledStart.map { $0.addingTimeInterval(Double(durationMinutes) * 60) }
    }

    /// Upcoming = confirmed or requested and not yet ended.
    var isUpcoming: Bool {
        guard status == .confirmed || status == .requested else { return false }
        guard let end = scheduledEnd else { return true }
        return end > Date()
    }

    /// The join button only arms shortly before the session and stays live
    /// through it — never for a session that's over or days away.
    var canJoin: Bool {
        guard status == .confirmed, let start = scheduledStart, zoomJoinUrl != nil else { return false }
        let now = Date()
        let opensAt = start.addingTimeInterval(-15 * 60)
        let closesAt = scheduledEnd ?? start.addingTimeInterval(3600)
        return now >= opensAt && now <= closesAt
    }

    var formattedWhen: String {
        guard let start = scheduledStart else { return "Time TBD" }
        return start.formatted(date: .abbreviated, time: .shortened)
    }

    var formattedTimeRange: String {
        guard let start = scheduledStart else { return "" }
        let s = start.formatted(date: .omitted, time: .shortened)
        guard let end = scheduledEnd else { return s }
        return "\(s) – \(end.formatted(date: .omitted, time: .shortened))"
    }
}

/// A client's private post-session reflection. Kept separate from `Appointment`
/// so a future provider-notes surface never shares a row with client-owned data.
struct AppointmentFeedback: Identifiable, Codable {
    let id: UUID
    var appointmentId: UUID
    var clientId: UUID
    var rating: Int?
    var reflection: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, rating, reflection
        case appointmentId
        case clientId
        case createdAt
    }
}

/// A provider a client may request a session with (from bookable_providers()).
struct BookableProvider: Identifiable, Codable, Hashable {
    let id: UUID
    let fullName: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id, role
        case fullName
    }

    var roleLabel: String {
        switch role {
        case "therapist": return "Therapist"
        case "case_manager": return "Case Manager"
        case "counselor": return "Counselor"
        case "admin": return "Admin"
        default: return role.capitalized
        }
    }
}
