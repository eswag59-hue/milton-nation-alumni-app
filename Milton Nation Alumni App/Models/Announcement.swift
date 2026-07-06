import Foundation

struct Announcement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var createdAt: Date
    /// The facility (florida / ohio) this announcement targets. `nil` for legacy
    /// rows (visible to all facilities). Set to the author's facility on create.
    var facility: Facility? = nil
    /// Client-side UI state — there is NO `is_expanded` column on the `announcements`
    /// table. Must be excluded from CodingKeys (would cause decode to throw keyNotFound).
    var isExpanded: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, description, facility
        case createdAt   // "created_at"
    }
}
