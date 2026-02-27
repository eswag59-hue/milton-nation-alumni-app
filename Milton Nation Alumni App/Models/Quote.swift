import Foundation

struct DailyQuote: Identifiable, Codable {
    let id: UUID
    var text: String
    var attribution: String
    var scheduledDate: Date?
}
