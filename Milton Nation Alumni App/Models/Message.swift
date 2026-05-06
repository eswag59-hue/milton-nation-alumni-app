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

    /// Client-side flag — not stored in the database; set after fetch.
    var isFromCurrentUser: Bool = false

    // Explicit keys needed for "mediaURL": .convertFromSnakeCase maps
    // "media_url" → "mediaUrl" (lowercase l), not "mediaURL" (uppercase L).
    // "isFromCurrentUser" is intentionally omitted: it's a client-side-only
    // property and will fall back to its default value (false) during decode.
    enum CodingKeys: String, CodingKey {
        case id, content, status
        case conversationId     // "conversation_id"  → "conversationId"
        case senderId           // "sender_id"        → "senderId"
        case messageType        // "message_type"     → "messageType"
        case mediaURL = "mediaUrl"  // "media_url"    → "mediaUrl"
        case fileName           // "file_name"        → "fileName"
        case voiceDuration      // "voice_duration"   → "voiceDuration"
        case matchedKeywords    // "matched_keywords" → "matchedKeywords"
        case createdAt          // "created_at"       → "createdAt"
    }
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

    // Explicit keys needed for "staffPhotoURL": .convertFromSnakeCase maps
    // "staff_photo_url" → "staffPhotoUrl" (lowercase l), not "staffPhotoURL".
    enum CodingKeys: String, CodingKey {
        case id
        case userId             // "user_id"          → "userId"
        case staffId            // "staff_id"         → "staffId"
        case staffName          // "staff_name"       → "staffName"
        case staffRole          // "staff_role"       → "staffRole"
        case staffPhotoURL = "staffPhotoUrl"  // "staff_photo_url" → "staffPhotoUrl"
        case lastMessage        // "last_message"     → "lastMessage"
        case lastMessageAt      // "last_message_at"  → "lastMessageAt"
        case unreadCount        // "unread_count"     → "unreadCount"
        case createdAt          // "created_at"       → "createdAt"
    }
}
