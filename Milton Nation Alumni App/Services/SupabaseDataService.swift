import Foundation
import Supabase

// MARK: - RPC Parameter Types
// Must be Sendable + Encodable and defined at file scope
// to avoid MainActor isolation issues with Supabase RPC calls.

nonisolated private struct ToggleLikeRPCParams: Encodable, Sendable {
    let pPostId: UUID
    let pUserId: UUID
    enum CodingKeys: String, CodingKey {
        case pPostId = "p_post_id"
        case pUserId = "p_user_id"
    }
}

nonisolated private struct IncrementCommentRPCParams: Encodable, Sendable {
    let pPostId: UUID
    enum CodingKeys: String, CodingKey {
        case pPostId = "p_post_id"
    }
}

nonisolated private struct AwardPointsRPCParams: Encodable, Sendable {
    let pUserId: UUID
    let pPoints: Int
    let pAction: String
    enum CodingKeys: String, CodingKey {
        case pUserId = "p_user_id"
        case pPoints = "p_points"
        case pAction = "p_action"
    }
}

// MARK: - Insert/Update Parameter Types

nonisolated private struct PostInsertParams: Encodable, Sendable {
    let userId: UUID
    let userName: String
    let userPhotoUrl: String?
    let category: String
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let status: String
    let matchedKeywords: [String]
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case userPhotoUrl = "user_photo_url"
        case category, content
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case status
        case matchedKeywords = "matched_keywords"
    }
}

nonisolated private struct CommentInsertParams: Encodable, Sendable {
    let postId: UUID
    let userId: UUID
    let userName: String
    let userPhotoUrl: String?
    let content: String
    let matchedKeywords: [String]
    let status: String
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case userName = "user_name"
        case userPhotoUrl = "user_photo_url"
        case content
        case matchedKeywords = "matched_keywords"
        case status
    }
}

nonisolated private struct MessageInsertParams: Encodable, Sendable {
    let conversationId: UUID
    let senderId: UUID
    let messageType: String
    let content: String?
    let status: String
    let matchedKeywords: [String]
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content, status
        case matchedKeywords = "matched_keywords"
    }
}

nonisolated private struct ProfileUpdateParams: Encodable, Sendable {
    let fullName: String
    let phone: String
    let username: String
    let profilePhotoUrl: String?
    let sobrietyDate: Date
    let recoveryProgram: String
    let updatedAt: Date
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case phone, username
        case profilePhotoUrl = "profile_photo_url"
        case sobrietyDate = "sobriety_date"
        case recoveryProgram = "recovery_program"
        case updatedAt = "updated_at"
    }
}

nonisolated private struct AnnouncementInsertParams: Encodable, Sendable {
    let title: String
    let description: String
}

nonisolated private struct MilestoneInsertParams: Encodable, Sendable {
    let userId: UUID
    let milestoneType: String
    let milestoneDate: String
    let pointsAwarded: Int
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case milestoneType = "milestone_type"
        case milestoneDate = "milestone_date"
        case pointsAwarded = "points_awarded"
    }
}

nonisolated private struct InviteSMSParams: Encodable, Sendable {
    let phone: String
    let name: String?
}

nonisolated private struct InviteSMSResponse: Decodable, Sendable {
    let success: Bool?
    let phone: String?
    let error: String?
}

nonisolated private struct ConversationRow: Decodable, Sendable {
    let id: UUID
    let userId: UUID
    let staffId: UUID
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCount: Int
    let createdAt: Date
    let staffProfile: StaffProfileRow?
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case staffId = "staff_id"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case staffProfile = "staff"
    }
}

nonisolated private struct StaffProfileRow: Decodable, Sendable {
    let fullName: String
    let role: UserRole
    let profilePhotoUrl: String?
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case role
        case profilePhotoUrl = "profile_photo_url"
    }
}

nonisolated private struct AssignmentRow: Decodable, Sendable {
    let staffProfile: User
    enum CodingKeys: String, CodingKey {
        case staffProfile = "staff"
    }
}

nonisolated private struct LikeRow: Decodable, Sendable {
    let postId: UUID
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
    }
}

nonisolated private struct UserApprovalNotifParams: Encodable, Sendable {
    let target: String
    let userId: String
    let title: String
    let body: String
    let data: [String: String]
}

/// Production data service using Supabase PostgREST + Storage.
///
/// Implements all 24 `DataServiceProtocol` methods.
/// Every ViewModel that works with `MockDataService` works with this
/// implementation — no view changes needed.
final class SupabaseDataService: DataServiceProtocol {

    private let client = SupabaseConfig.client

    /// The currently authenticated user's ID. Retrieved from the active session.
    private var currentUserId: UUID {
        get async throws {
            let session = try await client.auth.session
            return session.user.id
        }
    }

    // MARK: - Posts

    func fetchPosts(category: PostCategory?) async throws -> [CommunityPost] {
        let userId = try await currentUserId

        // Show approved posts from everyone, PLUS the current user's own
        // pending / pending_review / flagged posts so they can see their own
        // submissions while waiting for moderation.
        var query = client.from("posts")
            .select()
            .or("status.eq.approved,user_id.eq.\(userId.uuidString)")

        if let category {
            query = query.eq("category", value: category.rawValue)
        }

        var posts: [CommunityPost] = try await query
            .order("is_pinned", ascending: false)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        // Fetch user's likes to determine isLikedByCurrentUser
        let likedPostIds: [UUID] = try await fetchLikedPostIds(userId: userId)
        let likedSet = Set(likedPostIds)

        for i in posts.indices {
            posts[i].isLikedByCurrentUser = likedSet.contains(posts[i].id)
        }

        return posts
    }

    func createPost(
        content: String,
        category: PostCategory,
        mediaData: Data? = nil,
        mediaType: CommunityPost.MediaType? = nil,
        status: PostStatus = .pending,
        matchedKeywords: [String] = []
    ) async throws -> CommunityPost {
        let userId = try await currentUserId

        // Fetch the user's profile for display name
        let profile: User = try await client.from("profiles")
            .select("id, username, profile_photo_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Upload media if provided
        var mediaURL: String?
        if let mediaData {
            let fileExt = mediaType == .video ? "mp4" : "jpg"
            let filePath = "\(userId.uuidString)/\(UUID().uuidString).\(fileExt)"

            try await client.storage
                .from(SupabaseConfig.postMediaBucket)
                .upload(
                    filePath,
                    data: mediaData,
                    options: .init(contentType: mediaType == .video ? "video/mp4" : "image/jpeg")
                )

            // Generate a signed URL (7-day expiry so post images don't go dark)
            mediaURL = try await client.storage
                .from(SupabaseConfig.postMediaBucket)
                .createSignedURL(path: filePath, expiresIn: 604_800)
                .absoluteString
        }

        // Insert the post
        let insert = PostInsertParams(
            userId: userId,
            userName: profile.username,
            userPhotoUrl: profile.profilePhotoURL,
            category: category.rawValue,
            content: content,
            mediaUrl: mediaURL,
            mediaType: mediaType?.rawValue,
            status: status.rawValue,
            matchedKeywords: matchedKeywords
        )

        let post: CommunityPost = try await client.from("posts")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return post
    }

    func toggleLike(postId: UUID) async throws -> Bool {
        let userId = try await currentUserId

        let result: Bool = try await client.rpc(
            "toggle_like",
            params: ToggleLikeRPCParams(pPostId: postId, pUserId: userId)
        )
        .execute()
        .value

        return result
    }

    // MARK: - Comments

    func fetchComments(postId: UUID) async throws -> [Comment] {
        let comments: [Comment] = try await client.from("comments")
            .select()
            .eq("post_id", value: postId.uuidString)
            .order("created_at", ascending: true)
            .limit(100)
            .execute()
            .value

        return comments
    }

    func addComment(
        postId: UUID,
        content: String,
        status: PostStatus = .approved,
        matchedKeywords: [String] = []
    ) async throws -> Comment {
        let userId = try await currentUserId

        // Fetch user profile for display name
        let profile: User = try await client.from("profiles")
            .select("id, username, profile_photo_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        let insert = CommentInsertParams(
            postId: postId,
            userId: userId,
            userName: profile.username,
            userPhotoUrl: profile.profilePhotoURL,
            content: content,
            matchedKeywords: matchedKeywords,
            status: status.rawValue
        )

        let comment: Comment = try await client.from("comments")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Increment post comments count via RPC
        try await client.rpc(
            "increment_comment_count",
            params: IncrementCommentRPCParams(pPostId: postId)
        ).execute()

        return comment
    }

    // MARK: - Post Moderation (Admin)

    func fetchPendingPosts() async throws -> [CommunityPost] {
        let posts: [CommunityPost] = try await client.from("posts")
            .select()
            .in("status", values: ["pending", "pending_review", "flagged_for_crisis"])
            .order("created_at", ascending: false)
            .execute()
            .value

        return posts
    }

    func moderatePost(postId: UUID, action: PostStatus) async throws -> CommunityPost {
        var updateData: [String: String] = ["status": action.rawValue]

        if action == .approved {
            updateData["approved_at"] = ISO8601DateFormatter().string(from: Date())
        }

        let post: CommunityPost = try await client.from("posts")
            .update(updateData)
            .eq("id", value: postId.uuidString)
            .select()
            .single()
            .execute()
            .value

        // If approved, increment the author's approved post count.
        // PostgREST doesn't support column arithmetic in update payloads, so we
        // fetch the current value first and update with the incremented integer.
        if action == .approved {
            struct ApprovedCountRow: Decodable {
                let approvedPostCount: Int
                enum CodingKeys: String, CodingKey { case approvedPostCount = "approved_post_count" }
            }
            if let row = try? await (client.from("profiles")
                .select("approved_post_count")
                .eq("id", value: post.userId.uuidString)
                .single()
                .execute()
                .value as ApprovedCountRow) {
                _ = try? await client.from("profiles")
                    .update(["approved_post_count": row.approvedPostCount + 1])
                    .eq("id", value: post.userId.uuidString)
                    .execute()
            }
        }

        return post
    }

    func pinPost(postId: UUID, isPinned: Bool) async throws -> CommunityPost {
        let post: CommunityPost = try await client.from("posts")
            .update(["is_pinned": isPinned])
            .eq("id", value: postId.uuidString)
            .select()
            .single()
            .execute()
            .value

        return post
    }

    // MARK: - Meetings

    func fetchMeetings() async throws -> [Meeting] {
        // Fetch meetings
        let meetings: [Meeting] = try await client.from("meetings")
            .select()
            .gte("date", value: ISO8601DateFormatter().string(from: Date()))
            .order("date", ascending: true)
            .execute()
            .value

        // RSVPs are managed client-side via UserDefaults until realtime sync is added.
        // The rsvpUserIds field defaults to [] in the model.

        return meetings
    }

    // MARK: - Chat

    func fetchConversations() async throws -> [Conversation] {
        let userId = try await currentUserId

        let rows: [ConversationRow] = try await client.from("conversations")
            .select("*, staff:profiles!staff_id(full_name, role, profile_photo_url)")
            .eq("user_id", value: userId.uuidString)
            .order("last_message_at", ascending: false)
            .execute()
            .value

        return rows.map { row in
            Conversation(
                id: row.id,
                userId: row.userId,
                staffId: row.staffId,
                staffName: row.staffProfile?.fullName ?? "Staff",
                staffRole: row.staffProfile?.role ?? .caseManager,
                staffPhotoURL: row.staffProfile?.profilePhotoUrl,
                lastMessage: row.lastMessage,
                lastMessageAt: row.lastMessageAt,
                unreadCount: row.unreadCount,
                createdAt: row.createdAt
            )
        }
    }

    func fetchMessages(conversationId: UUID) async throws -> [ChatMessage] {
        let userId = try await currentUserId

        var messages: [ChatMessage] = try await client.from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .limit(200)
            .execute()
            .value

        // Set isFromCurrentUser for each message
        for i in messages.indices {
            messages[i].isFromCurrentUser = messages[i].senderId == userId
        }

        // Reset unread count for this conversation
        _ = try? await client.from("conversations")
            .update(["unread_count": 0])
            .eq("id", value: conversationId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()

        return messages
    }

    func sendMessage(
        conversationId: UUID,
        content: String,
        type: MessageType,
        status: MessageModerationStatus = .clean,
        matchedKeywords: [String] = []
    ) async throws -> ChatMessage {
        let userId = try await currentUserId

        let insert = MessageInsertParams(
            conversationId: conversationId,
            senderId: userId,
            messageType: type.rawValue,
            content: content,
            status: status.rawValue,
            matchedKeywords: matchedKeywords
        )

        var message: ChatMessage = try await client.from("messages")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        message.isFromCurrentUser = true

        // Update conversation's last message
        _ = try? await client.from("conversations")
            .update([
                "last_message": content,
                "last_message_at": ISO8601DateFormatter().string(from: Date()),
            ])
            .eq("id", value: conversationId.uuidString)
            .execute()

        return message
    }

    // MARK: - User

    func fetchAssignedStaff() async throws -> [User] {
        let userId = try await currentUserId

        let rows: [AssignmentRow] = try await client.from("staff_assignments")
            .select("staff:profiles!staff_id(*)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return rows.map(\.staffProfile)
    }

    func updateProfile(user: User) async throws -> User {
        let update = ProfileUpdateParams(
            fullName: user.fullName,
            phone: user.phone,
            username: user.username,
            profilePhotoUrl: user.profilePhotoURL,
            sobrietyDate: user.sobrietyDate,
            recoveryProgram: user.recoveryProgram,
            updatedAt: Date()
        )

        let updated: User = try await client.from("profiles")
            .update(update)
            .eq("id", value: user.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return updated
    }

    // MARK: - Quotes

    func fetchDailyQuote() async throws -> DailyQuote {
        // Pick today's quote by day-of-year, cycling through all quotes
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // First try to get a quote scheduled for today
        let today = Calendar.current.startOfDay(for: Date())
        let scheduledQuotes: [DailyQuote] = try await client.from("daily_quotes")
            .select()
            .eq("scheduled_date", value: ISO8601DateFormatter().string(from: today))
            .limit(1)
            .execute()
            .value

        if let scheduled = scheduledQuotes.first {
            return scheduled
        }

        // Otherwise, get all quotes and pick by day-of-year
        let allQuotes: [DailyQuote] = try await client.from("daily_quotes")
            .select()
            .execute()
            .value

        guard !allQuotes.isEmpty else {
            return DailyQuote(
                id: UUID(),
                text: "Every day is a new beginning.",
                attribution: "Unknown"
            )
        }

        let index = (dayOfYear - 1) % allQuotes.count
        return allQuotes[index]
    }

    // MARK: - Announcements

    func fetchAnnouncements() async throws -> [Announcement] {
        let announcements: [Announcement] = try await client.from("announcements")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return announcements
    }

    func createAnnouncement(title: String, description: String) async throws -> Announcement {
        let announcement: Announcement = try await client.from("announcements")
            .insert(AnnouncementInsertParams(title: title, description: description))
            .select()
            .single()
            .execute()
            .value

        return announcement
    }

    func updateAnnouncement(id: UUID, title: String, description: String) async throws -> Announcement {
        let announcement: Announcement = try await client.from("announcements")
            .update(["title": title, "description": description])
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return announcement
    }

    func deleteAnnouncement(id: UUID) async throws {
        try await client.from("announcements")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Badges & Points

    func fetchBadges() async throws -> [Badge] {
        let badges: [Badge] = try await client.from("badges")
            .select()
            .order("sort_order", ascending: true)
            .execute()
            .value

        return badges
    }

    func fetchUserBadges() async throws -> [UserBadge] {
        let userId = try await currentUserId

        let userBadges: [UserBadge] = try await client.from("user_badges")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return userBadges
    }

    func awardPoints(action: PointAction) async throws -> Int {
        let userId = try await currentUserId

        let newTotal: Int = try await client.rpc(
            "award_points",
            params: AwardPointsRPCParams(
                pUserId: userId,
                pPoints: action.points,
                pAction: action.rawValue
            )
        )
        .execute()
        .value

        return newTotal
    }

    func checkMilestones(user: User) async throws -> SobrietyMilestone? {
        let days = user.daysOfRecovery
        let milestoneType: SobrietyMilestone.MilestoneType?

        switch days {
        case 30:  milestoneType = .thirtyDays
        case 60:  milestoneType = .sixtyDays
        case 90:  milestoneType = .ninetyDays
        case 180: milestoneType = .sixMonths
        case 365: milestoneType = .oneYear
        default:
            if days > 365 && days % 365 == 0 {
                milestoneType = .yearly
            } else {
                milestoneType = nil
            }
        }

        guard let type = milestoneType else { return nil }

        // Check if this milestone was already recorded
        let existing: [SobrietyMilestone] = try await client.from("sobriety_milestones")
            .select()
            .eq("user_id", value: user.id.uuidString)
            .eq("milestone_type", value: type.rawValue)
            .limit(1)
            .execute()
            .value

        if !existing.isEmpty { return nil } // Already recorded

        // Record the milestone
        let milestone: SobrietyMilestone = try await client.from("sobriety_milestones")
            .insert(MilestoneInsertParams(
                userId: user.id,
                milestoneType: type.rawValue,
                milestoneDate: ISO8601DateFormatter().string(from: Date()),
                pointsAwarded: type.points
            ))
            .select()
            .single()
            .execute()
            .value

        // Also award the points
        _ = try? await awardPoints(action: .milestoneReached)

        return milestone
    }

    // MARK: - User Approval

    func fetchPendingUsers() async throws -> [User] {
        try await fetchPendingUsers(facilityFilter: nil)
    }

    func fetchPendingUsers(facilityFilter: Facility?) async throws -> [User] {
        var query = client.from("profiles")
            .select()
            .eq("status", value: "pending")

        if let facility = facilityFilter {
            query = query.eq("facility", value: facility.rawValue)
        }

        let users: [User] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value

        return users
    }

    func approveUser(userId: UUID, facility: Facility) async throws -> User {
        let user: User = try await client.from("profiles")
            .update(["status": "active", "facility": facility.rawValue])
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value

        // Push notification to the newly approved user — non-blocking
        let approvedUserId = userId.uuidString
        Task {
            _ = try? await client.functions.invoke(
                "send-push-notification",
                options: .init(method: .post, body: UserApprovalNotifParams(
                    target: "user",
                    userId: approvedUserId,
                    title: "You're Approved! 🎉",
                    body: "Your Milton Nation account is now active. Welcome to the community!",
                    data: ["type": "account_approved"]
                ))
            )
        }

        return user
    }

    func rejectUser(userId: UUID) async throws {
        try await client.from("profiles")
            .update(["status": "rejected"])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Invite

    func sendInvite(phone: String, name: String?) async throws -> String {
        let params = InviteSMSParams(phone: phone, name: name)
        let response: InviteSMSResponse = try await client.functions.invoke(
            "send-invite-sms",
            options: .init(
                method: .post,
                body: params
            )
        )

        if let error = response.error {
            throw NSError(domain: "invite", code: 500, userInfo: [NSLocalizedDescriptionKey: error])
        }

        return response.phone ?? phone
    }

    // MARK: - Private Helpers

    /// Fetch the set of post IDs the current user has liked.
    private func fetchLikedPostIds(userId: UUID) async throws -> [UUID] {
        let rows: [LikeRow] = try await client.from("likes")
            .select("post_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return rows.map(\.postId)
    }
}
