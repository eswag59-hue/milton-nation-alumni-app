import Foundation

/// An open "notify my care team" alert, read from the care_team_alerts queue.
/// The member identity lives here (post-auth, HIPAA-covered) — never in the
/// push payload. A responder taps through to the member's chat and acknowledges.
struct CareTeamAlert: Identifiable, Codable {
    let id: UUID
    var memberId: UUID
    var facility: Facility?
    var kind: String
    var status: String
    var createdAt: Date

    /// Resolved from the joined profile after fetch.
    var memberName: String?

    enum CodingKeys: String, CodingKey {
        case id, facility, kind, status
        case memberId
        case createdAt
    }

    var when: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}
