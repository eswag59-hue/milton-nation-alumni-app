import Foundation

struct Announcement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var createdAt: Date
    /// Client-side UI state — there is NO `is_expanded` column on the `announcements`
    /// table. Must be excluded from CodingKeys (would cause decode to throw keyNotFound).
    var isExpanded: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case createdAt   // "created_at"
    }
}
