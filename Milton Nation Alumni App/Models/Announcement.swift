import Foundation

struct Announcement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var isExpanded: Bool = false
}
