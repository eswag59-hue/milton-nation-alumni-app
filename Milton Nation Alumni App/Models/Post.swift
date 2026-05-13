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
    /// Client-side UI state — there is NO matching database column. The DB tracks
    /// likes in a separate `likes` table; `SupabaseDataService.fetchPosts()` populates
    /// this flag after decode. Must NOT appear in CodingKeys (would throw keyNotFound).
    var isLikedByCurrentUser: Bool = false
    var matchedKeywords: [String] = []
    var createdAt: Date
    var approvedAt: Date?

    enum MediaType: String, Codable {
        case image, video
    }

    // Explicit keys needed for any property whose name ends in "URL":
    // .convertFromSnakeCase maps "user_photo_url" → "userPhotoUrl" (lowercase l),
    // which doesn't match the Swift property "userPhotoURL" (uppercase L).
    //
    // `isLikedByCurrentUser` is INTENTIONALLY excluded — it's client-side UI state
    // populated by the data service after decode (see comment above).
    enum CodingKeys: String, CodingKey {
        case id, category, content, status
        case userId             // "user_id"          → "userId"
        case userName           // "user_name"        → "userName"
        case userPhotoURL = "userPhotoUrl"  // "user_photo_url"  → "userPhotoUrl"
        case mediaURL = "mediaUrl"          // "media_url"       → "mediaUrl"
        case mediaType          // "media_type"       → "mediaType"
        case isPinned           // "is_pinned"        → "isPinned"
        case likesCount         // "likes_count"      → "likesCount"
        case commentsCount      // "comments_count"   → "commentsCount"
        case matchedKeywords    // "matched_keywords" → "matchedKeywords"
        case createdAt          // "created_at"       → "createdAt"
        case approvedAt         // "approved_at"      → "approvedAt"
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
    /// Number of likes on this comment. Server-tracked via the `comment_likes`
    /// table + a trigger on the comments table. Default 0 for backwards-compat.
    var likesCount: Int = 0
    /// Client-side flag set by SupabaseDataService.fetchComments after merging
    /// with the user's row from comment_likes. Always excluded from CodingKeys
    /// (same pattern as CommunityPost.isLikedByCurrentUser).
    var isLikedByCurrentUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, content, status
        case postId             // "post_id"          → "postId"
        case userId             // "user_id"          → "userId"
        case userName           // "user_name"        → "userName"
        case userPhotoURL = "userPhotoUrl"  // "user_photo_url"  → "userPhotoUrl"
        case matchedKeywords    // "matched_keywords" → "matchedKeywords"
        case createdAt          // "created_at"       → "createdAt"
        case likesCount         // "likes_count"      → "likesCount"
    }
}

struct Like: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    var createdAt: Date
}
