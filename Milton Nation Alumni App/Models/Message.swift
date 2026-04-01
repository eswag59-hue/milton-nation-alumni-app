import Foundation

enum MessageType: String, Codable {
    case text, image, voice, file
}

enum MessageModerationStatus: String, Codable {
    case clean
    case pending
    case flagged
    case flaggedForCrisis = "flagged_for_crisis"
    case approved
    case denied
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    var messageType: MessageType
    var content: String?
    var mediaURL: String?
    var fileName: String?
    var voiceDuration: TimeInterval?   // seconds; nil when unknown
    var status: MessageModerationStatus = .clean
    var matchedKeywords: [String] = []
    var createdAt: Date

    var isFromCurrentUser: Bool = false
}

struct Conversation: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let staffId: UUID
    var staffName: String
    var staffRole: UserRole
    var staffPhotoURL: String?
    var lastMessage: String?
    var lastMessageAt: Date?
    var unreadCount: Int
    var createdAt: Date
}
