import Foundation

enum PostCategory: String, Codable, CaseIterable {
    case wins, struggles, support, gratitude, general

    var displayName: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .wins: return "🎉"
        case .struggles: return "💪"
        case .support: return "🤝"
        case .gratitude: return "🙏"
        case .general: return "💬"
        }
    }
}

enum PostStatus: String, Codable {
    case pending, approved, rejected
    case pendingReview = "pending_review"
    case flaggedForCrisis = "flagged_for_crisis"
}

struct CommunityPost: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var userName: String
    var userPhotoURL: String?
    var category: PostCategory
    var content: String
    var mediaURL: String?
    var mediaType: MediaType?
    var status: PostStatus
    var isPinned: Bool = false
    var likesCount: Int
    var commentsCount: Int
    var isLikedByCurrentUser: Bool
    var matchedKeywords: [String] = []
    var createdAt: Date
    var approvedAt: Date?

    enum MediaType: String, Codable {
        case image, video
    }
}

struct Comment: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    var userName: String
    var userPhotoURL: String?
    var content: String
    var matchedKeywords: [String] = []
    var status: PostStatus
    var createdAt: Date
}

struct Like: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    var createdAt: Date
}
