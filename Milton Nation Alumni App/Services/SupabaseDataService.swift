import Foundation
import Supabase

// MARK: - RPC Parameter Types
// Must be Sendable + Encodable and defined at file scope
// to avoid MainActor isolation issues with Supabase RPC calls.

/// Params for `toggle_like(p_post_id uuid)` RPC. The function derives the
/// caller from auth.uid() server-side — do NOT pass a user id; an extra
/// param makes PostgREST fail to resolve the function (silent like failure).
nonisolated private struct ToggleLikeRPCParams: Encodable, Sendable {
    let pPostId: UUID
    enum CodingKeys: String, CodingKey {
        case pPostId
    }
}

nonisolated private struct IncrementCommentRPCParams: Encodable, Sendable {
    let pPostId: UUID
    enum CodingKeys: String, CodingKey {
        case pPostId
    }
}

/// Params for `toggle_comment_like(p_comment_id uuid)` RPC — auth.uid() is
/// derived server-side (same contract as `toggle_like`).
/// Returns the new like state (true if just-liked, false if just-unliked).
nonisolated private struct ToggleCommentLikeRPCParams: Encodable, Sendable {
    let pCommentId: UUID
    enum CodingKeys: String, CodingKey {
        case pCommentId
    }
}

/// Update params for editing an existing post — content + media. Sending the
/// post back to `pending_review` is done explicitly here so an admin must
/// re-approve user edits before they're visible to the rest of the community.
nonisolated private struct PostUpdateParams: Encodable, Sendable {
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let status: String
    enum CodingKeys: String, CodingKey {
        case content
        case mediaUrl
        case mediaType
        case status
    }
}

nonisolated private struct AwardPointsRPCParams: Encodable, Sendable {
    let pUserId: UUID
    let pPoints: Int
    let pAction: String
    enum CodingKeys: String, CodingKey {
        case pUserId
        case pPoints
        case pAction
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
    let mediaUrls: [String]?
    let mediaType: String?
    let status: String
    let matchedKeywords: [String]
    /// The author's facility (florida / ohio). Without this, posts insert NULL
    /// and become visible cross-facility (FL <-> OH data leak — PHI). `nil` only
    /// if the author has no facility assigned yet (pending), in which case the
    /// column is omitted and the row stays legacy-visible until re-migrated.
    let facility: String?
    enum CodingKeys: String, CodingKey {
        case userId
        case userName
        case userPhotoUrl
        case category, content
        case mediaUrl
        case mediaUrls
        case mediaType
        case status
        case matchedKeywords
        case facility
    }
}

/// Minimal profile row used when creating a post / announcement: just the
/// display fields plus the author's facility. Decoding into this instead of the
/// full `User` avoids keyNotFound on the many NOT-NULL `User` fields we don't
/// select, and gives us the facility needed for cross-facility isolation.
nonisolated private struct PostAuthorProfile: Decodable, Sendable {
    let id: UUID
    let username: String
    let profilePhotoUrl: String?
    /// Raw facility string ("florida" / "ohio") or nil if unassigned.
    let facility: String?
    enum CodingKeys: String, CodingKey {
        case id, username, facility
        case profilePhotoUrl
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
        case postId
        case userId
        case userName
        case userPhotoUrl
        case content
        case matchedKeywords
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
        case conversationId
        case senderId
        case messageType
        case content, status
        case matchedKeywords
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
        case fullName
        case phone, username
        case profilePhotoUrl
        case sobrietyDate
        case recoveryProgram
        case updatedAt
    }
}

nonisolated private struct AnnouncementInsertParams: Encodable, Sendable {
    let title: String
    let description: String
    /// Target facility ("florida" / "ohio"). nil = global (super_admin) or legacy.
    let facility: String?
}

/// Row used to resolve the caller's effective facility for RLS-style filtering.
/// Mirrors the SQL `current_user_facility()` helper: admins/staff use
/// `admin_facility`, alumni/pending use `facility`, super_admin resolves to nil.
nonisolated private struct CallerFacilityRow: Decodable, Sendable {
    let role: UserRole
    let facility: String?
    let adminFacility: String?
    enum CodingKeys: String, CodingKey {
        case role, facility
        case adminFacility
    }
    /// The facility to scope this caller's reads/writes to. nil = see/act on all
    /// (super_admin) or unassigned.
    var effectiveFacility: String? {
        switch role {
        case .superAdmin:
            return nil
        case .admin, .caseManager, .therapist, .counselor:
            return adminFacility
        case .alumni:
            return facility
        }
    }
}

nonisolated private struct MilestoneInsertParams: Encodable, Sendable {
    let userId: UUID
    let milestoneType: String
    let milestoneDate: String
    let pointsAwarded: Int
    enum CodingKeys: String, CodingKey {
        case userId
        case milestoneType
        case milestoneDate
        case pointsAwarded
    }
}

nonisolated private struct InviteEmailParams: Encodable, Sendable {
    let to: String
    let name: String?
}

nonisolated private struct InviteEmailResponse: Decodable, Sendable {
    let sent: Bool?
    let email: String?
    let reason: String?
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
        case userId
        case staffId
        case lastMessage
        case lastMessageAt
        case unreadCount
        case createdAt
        case staffProfile = "staff"
    }
}

nonisolated private struct StaffProfileRow: Decodable, Sendable {
    let fullName: String
    let role: UserRole
    let profilePhotoUrl: String?
    enum CodingKeys: String, CodingKey {
        case fullName
        case role
        case profilePhotoUrl
    }
}

/// Staff-side conversation row: same conversation, but joined to the CLIENT
/// (user_id) profile instead of the staff profile, so a case manager / therapist
/// sees WHO their client is on each thread.
nonisolated private struct ClientConversationRow: Decodable, Sendable {
    let id: UUID
    let userId: UUID
    let staffId: UUID
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCount: Int
    let createdAt: Date
    let clientProfile: StaffProfileRow?
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case staffId
        case lastMessage
        case lastMessageAt
        case unreadCount
        case createdAt
        case clientProfile = "client"
    }
}

/// Staff profiles can have NULL phone / mfa_method / sobriety dates (staff
/// never log sobriety). Decoding them as a full `User` (which requires those
/// fields) threw valueNotFound and silently killed the chat screen — so we
/// decode a null-tolerant row and map to `User` with safe defaults.
nonisolated private struct StaffLiteRow: Decodable, Sendable {
    let id: UUID
    let email: String?
    let phone: String?
    let fullName: String
    let username: String?
    let profilePhotoUrl: String?
    let sobrietyDate: Date?
    let dischargeDate: Date?
    let recoveryProgram: String?
    let role: UserRole
    let status: UserStatus
    let mfaMethod: MFAMethod?
    let totalPoints: Int?
    let lastLogin: Date?
    let createdAt: Date
    let updatedAt: Date?
    let facility: Facility?

    func toUser() -> User {
        var u = User(
            id: id,
            email: email ?? "",
            phone: phone ?? "",
            fullName: fullName,
            username: username ?? fullName.lowercased().replacingOccurrences(of: " ", with: "_"),
            profilePhotoURL: profilePhotoUrl,
            sobrietyDate: sobrietyDate ?? createdAt,
            dischargeDate: dischargeDate ?? createdAt,
            recoveryProgram: recoveryProgram ?? "",
            role: role,
            status: status,
            mfaMethod: mfaMethod ?? .sms,
            totalPoints: totalPoints ?? 0,
            lastLogin: lastLogin ?? createdAt,
            lastPointsAwarded: nil,
            createdAt: createdAt,
            updatedAt: updatedAt ?? createdAt
        )
        u.facility = facility
        return u
    }
}

nonisolated private struct AssignmentRow: Decodable, Sendable {
    let staffProfile: StaffLiteRow
    enum CodingKeys: String, CodingKey {
        case staffProfile = "staff"
    }
}

nonisolated private struct LikeRow: Decodable, Sendable {
    let postId: UUID
    enum CodingKeys: String, CodingKey {
        case postId
    }
}

nonisolated private struct CommentLikeRow: Decodable, Sendable {
    let commentId: UUID
    enum CodingKeys: String, CodingKey {
        case commentId
    }
}

nonisolated private struct UserApprovalNotifParams: Encodable, Sendable {
    let target: String
    let userId: String
    let title: String
    let body: String
    let data: [String: String]
}

// MARK: - Block (blocked_users table) Param Types

/// Insert payload for `blocked_users`. `blocker_id` is set explicitly even
/// though RLS enforces `blocker_id = auth.uid()` — defense in depth.
nonisolated private struct BlockInsertParams: Encodable, Sendable {
    let blockerId: String
    let blockedId: String
    enum CodingKeys: String, CodingKey {
        case blockerId
        case blockedId
    }
}

/// Row shape for reading `blocked_users` (just the blocked party's id).
nonisolated private struct BlockedRow: Decodable, Sendable {
    let blockedId: UUID
    enum CodingKeys: String, CodingKey {
        case blockedId
    }
}

/// Minimal profile row used to resolve a blocked user's display name.
nonisolated private struct BlockedProfileRow: Decodable, Sendable {
    let id: UUID
    let username: String?
    let fullName: String?
    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName
    }
}

// MARK: - Data Export Row Types (HIPAA Right of Access)

/// Minimal post row for the "Download My Data" export — content only, no ids.
nonisolated private struct ExportPostRow: Decodable, Sendable {
    let content: String
    let category: String
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case content, category
        case createdAt
    }
}

/// Minimal comment row for the "Download My Data" export.
nonisolated private struct ExportCommentRow: Decodable, Sendable {
    let content: String
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case content
        case createdAt
    }
}

/// Minimal message row for the "Download My Data" export. `content` is
/// nullable in the schema (media-only messages), so it decodes as optional.
nonisolated private struct ExportMessageRow: Decodable, Sendable {
    let content: String?
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case content
        case createdAt
    }
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

    /// Per-session cache of the current caller's effective facility. `nil` means
    /// "not loaded yet"; a loaded value of `.some(nil)` means super_admin / no
    /// facility. Loaded lazily and reused so we don't re-query per fetch.
    private var callerFacilityCache: String??

    /// Returns the caller's effective facility (super_admin / unassigned = nil),
    /// used to filter feeds client-side so FL never sees OH and vice versa.
    /// Failures degrade to `nil` (see-all) rather than hiding the whole feed —
    /// server-side RLS remains the authoritative isolation boundary.
    private func currentUserFacility() async -> String? {
        if let cached = callerFacilityCache { return cached }
        let resolved: String? = await {
            guard let userId = try? await currentUserId else { return nil }
            let row: CallerFacilityRow? = try? await client.from("profiles")
                .select("role, facility, admin_facility")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return row?.effectiveFacility
        }()
        callerFacilityCache = .some(resolved)
        return resolved
    }

    /// Per-session cache of the user IDs the current user has blocked. Populated
    /// lazily on first feed fetch and refreshed after block/unblock. Used to
    /// filter posts, comments, conversations, and messages client-side so we
    /// never have to change the server query logic. `nil` = not loaded yet.
    private var blockedUserIdsCache: Set<UUID>?

    /// Returns the cached blocked-set, loading it from `blocked_users` on first
    /// use. Failures degrade gracefully to an empty set so a transient error
    /// never hides the whole feed.
    private func blockedUserIds() async -> Set<UUID> {
        if let cache = blockedUserIdsCache { return cache }
        let set = (try? await fetchBlockedUserIds()) ?? []
        blockedUserIdsCache = set
        return set
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

        // Facility isolation (PHI): a user only sees their own facility's posts.
        // super_admin (facility == nil) sees all. Legacy rows with a nil facility
        // stay visible to everyone until re-migrated. The user's OWN posts always
        // pass so they can see their submissions even if unstamped. This mirrors
        // the server-side RLS `posts_select_facility` policy — defense in depth.
        if let myFacilityRaw = await currentUserFacility() {
            posts = posts.filter { post in
                post.userId == userId
                    || post.facility == nil
                    || post.facility?.rawValue == myFacilityRaw
            }
        }

        // Hide posts authored by blocked users (Apple Guideline 1.2). We filter
        // the returned array rather than touching the server query — never hide
        // the user's OWN posts (a user can't block themselves anyway).
        let blocked = await blockedUserIds()
        if !blocked.isEmpty {
            posts = posts.filter { !blocked.contains($0.userId) }
        }

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
        additionalImageDatas: [Data] = [],
        status: PostStatus = .pending,
        matchedKeywords: [String] = []
    ) async throws -> CommunityPost {
        let userId = try await currentUserId

        // Fetch the user's profile for display name + facility. We decode into a
        // minimal struct (not the full `User`) so a partial column select can't
        // throw keyNotFound on the many NOT-NULL User fields we don't select here.
        let profile: PostAuthorProfile = try await client.from("profiles")
            .select("id, username, profile_photo_url, facility")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Upload media if provided. A single helper uploads one blob and returns
        // its signed URL (7-day expiry so post images don't go dark).
        // Lowercase uuid: the post-media storage policy compares the first path
        // folder to auth.uid()::text (lowercase); uppercase → upload denied.
        func uploadBlob(_ data: Data, isVideo: Bool) async throws -> String {
            let fileExt = isVideo ? "mp4" : "jpg"
            let filePath = "\(userId.uuidString.lowercased())/\(UUID().uuidString).\(fileExt)"
            try await client.storage
                .from(SupabaseConfig.postMediaBucket)
                .upload(filePath, data: data,
                        options: .init(contentType: isVideo ? "video/mp4" : "image/jpeg"))
            return try await client.storage
                .from(SupabaseConfig.postMediaBucket)
                .createSignedURL(path: filePath, expiresIn: 604_800)
                .absoluteString
        }

        var mediaURL: String?
        var mediaURLs: [String] = []
        if let mediaData {
            let isVideo = mediaType == .video
            let first = try await uploadBlob(mediaData, isVideo: isVideo)
            mediaURL = first
            if !isVideo {
                mediaURLs.append(first)
                // Upload any additional photos for a multi-photo post.
                for extra in additionalImageDatas {
                    mediaURLs.append(try await uploadBlob(extra, isVideo: false))
                }
            }
        }

        // Insert the post — stamp it with the author's facility so RLS + the
        // client-side filter keep FL and OH content separate (PHI isolation).
        let insert = PostInsertParams(
            userId: userId,
            userName: profile.username,
            userPhotoUrl: profile.profilePhotoUrl,
            category: category.rawValue,
            content: content,
            mediaUrl: mediaURL,
            mediaUrls: mediaURLs.isEmpty ? nil : mediaURLs,
            mediaType: mediaType?.rawValue,
            status: status.rawValue,
            matchedKeywords: matchedKeywords,
            facility: profile.facility
        )

        // supabase-swift 2.41.1 has a bug where `.insert(...).select().single()`
        // does NOT set Accept: application/vnd.pgrst.object+json on the request,
        // so the server returns a JSON array (one element) instead of a single
        // object. Swift's decoder then throws "data couldn't be read because it
        // is missing" when it sees `[` where it expected `{`. We work around it
        // by decoding the response as an array and taking the first element.
        // (Same workaround applied to every insert+select+single site in this file.)
        let inserted: [CommunityPost] = try await client.from("posts")
            .insert(insert)
            .select()
            .execute()
            .value
        guard let post = inserted.first else {
            throw NSError(domain: "SupabaseDataService.createPost", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned empty response on insert."])
        }

        return post
    }

    func toggleLike(postId: UUID) async throws -> Bool {
        _ = try await currentUserId  // auth guard — throws if signed out

        let result: Bool = try await client.rpc(
            "toggle_like",
            params: ToggleLikeRPCParams(pPostId: postId)
        )
        .execute()
        .value

        return result
    }

    func deletePost(postId: UUID) async throws {
        let userId = try await currentUserId
        // RLS policy on posts enforces user_id == auth.uid() so we explicitly
        // scope the DELETE by user_id too — defense in depth, fails fast if
        // someone tries to call this with another user's post id.
        try await client.from("posts")
            .delete()
            .eq("id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Comments

    func fetchComments(postId: UUID) async throws -> [Comment] {
        var comments: [Comment] = try await client.from("comments")
            .select()
            .eq("post_id", value: postId.uuidString)
            .order("created_at", ascending: true)
            .limit(100)
            .execute()
            .value

        // Hide comments from blocked users (Apple Guideline 1.2).
        let blocked = await blockedUserIds()
        if !blocked.isEmpty {
            comments = comments.filter { !blocked.contains($0.userId) }
        }

        // Merge the current user's like state from `comment_likes`. We do this
        // client-side (rather than a join) so the Comment Codable shape stays
        // simple — `isLikedByCurrentUser` is excluded from CodingKeys and is
        // explicitly NOT a database column.
        let userId = try await currentUserId
        let likedIds = try await fetchLikedCommentIds(userId: userId, postId: postId)
        let likedSet = Set(likedIds)
        for i in comments.indices {
            comments[i].isLikedByCurrentUser = likedSet.contains(comments[i].id)
        }

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

        // See createPost comment re: supabase-swift 2.41.1 insert+single bug.
        let insertedComments: [Comment] = try await client.from("comments")
            .insert(insert)
            .select()
            .execute()
            .value
        guard let comment = insertedComments.first else {
            throw NSError(domain: "SupabaseDataService.submitComment", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned empty response on insert."])
        }

        // Increment post comments count via RPC
        try await client.rpc(
            "increment_comment_count",
            params: IncrementCommentRPCParams(pPostId: postId)
        ).execute()

        return comment
    }

    /// Toggle the like state on a comment.
    /// Delegates to `toggle_comment_like(p_comment_id, p_user_id)` RPC which
    /// inserts/deletes the comment_likes row AND maintains likes_count via
    /// trigger. Returns the new isLiked state.
    func toggleCommentLike(commentId: UUID) async throws -> Bool {
        _ = try await currentUserId  // auth guard — throws if signed out

        let result: Bool = try await client.rpc(
            "toggle_comment_like",
            params: ToggleCommentLikeRPCParams(pCommentId: commentId)
        )
        .execute()
        .value

        return result
    }

    /// Edit the content (and optionally media) of a post the current user owns.
    /// Sends the post back to `pending_review` so an admin must re-approve it
    /// before the rest of the community sees the edit. RLS enforces ownership.
    func updatePostContent(
        postId: UUID,
        newContent: String,
        newMediaURL: String?,
        newMediaType: CommunityPost.MediaType?
    ) async throws -> CommunityPost {
        let userId = try await currentUserId

        let params = PostUpdateParams(
            content: newContent,
            mediaUrl: newMediaURL,
            mediaType: newMediaType?.rawValue,
            status: PostStatus.pendingReview.rawValue
        )

        let post: CommunityPost = try await client.from("posts")
            .update(params)
            .eq("id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value

        return post
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
                enum CodingKeys: String, CodingKey { case approvedPostCount }
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

    func createMeeting(_ meeting: Meeting) async throws -> Meeting {
        // See createPost comment re: supabase-swift 2.41.1 insert+single bug.
        let insertedMeetings: [Meeting] = try await client.from("meetings")
            .insert(meeting)
            .select()
            .execute()
            .value
        guard let inserted = insertedMeetings.first else {
            throw NSError(domain: "SupabaseDataService.createMeeting", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned empty response on insert."])
        }
        return inserted
    }

    func updateMeeting(_ meeting: Meeting) async throws -> Meeting {
        let updated: Meeting = try await client.from("meetings")
            .update(meeting)
            .eq("id", value: meeting.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }

    func deleteMeeting(meetingId: UUID) async throws {
        try await client.from("meetings")
            .delete()
            .eq("id", value: meetingId.uuidString)
            .execute()
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

        // Hide conversations whose other participant has been blocked (Guideline 1.2).
        let blocked = await blockedUserIds()
        let visibleRows = blocked.isEmpty ? rows : rows.filter { !blocked.contains($0.staffId) }

        return visibleRows.map { row in
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

    /// The caseload for a logged-in staff member: every conversation where they
    /// are the assigned staff, with the CLIENT surfaced as the display party.
    /// We reuse the `Conversation` model — the "staff*" fields carry the client
    /// so the existing ChatDetailScreen renders the client's name as the title.
    func fetchClientConversations() async throws -> [Conversation] {
        let staffId = try await currentUserId

        let rows: [ClientConversationRow] = try await client.from("conversations")
            .select("*, client:profiles!user_id(full_name, role, profile_photo_url)")
            .eq("staff_id", value: staffId.uuidString)
            .order("last_message_at", ascending: false)
            .execute()
            .value

        return rows.map { row in
            Conversation(
                id: row.id,
                userId: row.userId,
                staffId: row.staffId,
                staffName: row.clientProfile?.fullName ?? "Client",
                staffRole: row.clientProfile?.role ?? .alumni,
                staffPhotoURL: row.clientProfile?.profilePhotoUrl,
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

        // Hide messages authored by blocked senders (Guideline 1.2). The user's
        // own messages always pass (you can't block yourself).
        let blocked = await blockedUserIds()
        if !blocked.isEmpty {
            messages = messages.filter { $0.senderId == userId || !blocked.contains($0.senderId) }
        }

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

        // See createPost comment re: supabase-swift 2.41.1 insert+single bug.
        let insertedMessages: [ChatMessage] = try await client.from("messages")
            .insert(insert)
            .select()
            .execute()
            .value
        guard var message = insertedMessages.first else {
            throw NSError(domain: "SupabaseDataService.sendMessage", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned empty response on insert."])
        }

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

        return rows.map { $0.staffProfile.toUser() }
    }

    /// Newest-first audit trail. Joins the actor's name so a reviewer sees a
    /// person, not a UUID. RLS ("Admins read audit logs") is the access gate.
    func fetchAuditLog(limit: Int) async throws -> [AuditLogRecord] {
        struct Row: Decodable {
            let id: UUID
            let action: String
            let userId: UUID?
            let detail: String?
            let ipAddress: String?
            let createdAt: Date
        }

        let rows: [Row] = try await client.from("audit_logs")
            // No embedded profile join: audit_logs.user_id has no FK to
            // profiles by design — the trail must survive a purged account.
            // Names are resolved by the caller from its loaded roster.
            .select("id, action, user_id, detail, ip_address, created_at")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows.map {
            AuditLogRecord(
                id: $0.id,
                action: $0.action,
                userId: $0.userId,
                detail: $0.detail,
                ipAddress: $0.ipAddress,
                createdAt: $0.createdAt,
                userName: nil
            )
        }
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

    func deactivateAccount(userId: UUID) async throws {
        // Mark deactivated + stamp the 30-day clock. `updateProfile` intentionally
        // does NOT write `status`/`deactivated_at`, so account deletion goes
        // through this dedicated path. The daily `purge_deactivated_accounts()`
        // job hard-deletes personal data once deactivated_at is >30 days old.
        struct DeactivateParams: Encodable {
            let status: String
            let deactivatedAt: String
            enum CodingKeys: String, CodingKey {
                case status
                case deactivatedAt
            }
        }
        let params = DeactivateParams(
            status: "deactivated",
            deactivatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try await client.from("profiles")
            .update(params)
            .eq("id", value: userId.uuidString)
            .execute()
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
        var announcements: [Announcement] = try await client.from("announcements")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        // Facility isolation (PHI): only show announcements for the caller's
        // facility. super_admin (facility == nil) sees all; legacy rows with a
        // nil facility stay visible to everyone. Mirrors the server-side RLS
        // `announcements_select_facility` policy — defense in depth.
        if let myFacilityRaw = await currentUserFacility() {
            announcements = announcements.filter { ann in
                ann.facility == nil || ann.facility?.rawValue == myFacilityRaw
            }
        }

        return announcements
    }

    func createAnnouncement(title: String, description: String) async throws -> Announcement {
        // Stamp the announcement with the author's facility so FL and OH members
        // only see announcements meant for them. super_admin resolves to nil =
        // a global announcement visible to all facilities.
        let facility = await currentUserFacility()

        // See createPost comment re: supabase-swift 2.41.1 insert+single bug.
        let inserted: [Announcement] = try await client.from("announcements")
            .insert(AnnouncementInsertParams(title: title, description: description, facility: facility))
            .select()
            .execute()
            .value
        guard let announcement = inserted.first else {
            throw NSError(domain: "SupabaseDataService.createAnnouncement", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned empty response on insert."])
        }

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
        // See createPost comment re: supabase-swift 2.41.1 insert+single bug.
        let insertedMilestones: [SobrietyMilestone] = try await client.from("sobriety_milestones")
            .insert(MilestoneInsertParams(
                userId: user.id,
                milestoneType: type.rawValue,
                milestoneDate: ISO8601DateFormatter().string(from: Date()),
                pointsAwarded: type.points
            ))
            .select()
            .execute()
            .value
        guard let milestone = insertedMilestones.first else {
            throw NSError(domain: "SupabaseDataService.recordMilestone", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Server returned empty response on insert."])
        }

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
            // Include signups with NO facility yet. A new member often hasn't been
            // assigned a facility — the admin assigns it AT approval time (the
            // Florida/Ohio toggle in the approval card). Filtering strictly by
            // facility hid every unassigned applicant, so the queue looked empty
            // and new members could never be approved.
            query = query.or("facility.eq.\(facility.rawValue),facility.is.null")
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

    // MARK: - Admin: Roster & Assignments

    func fetchAlumniUsers(facility: Facility?) async throws -> [User] {
        var query = client.from("profiles")
            .select()
            .eq("role", value: "alumni")
            .eq("status", value: "active")
        if let facility {
            query = query.eq("facility", value: facility.rawValue)
        }
        let users: [User] = try await query
            .order("full_name", ascending: true)
            .execute()
            .value
        return users
    }

    func fetchStaffMembers(facility: Facility?) async throws -> [User] {
        var query = client.from("profiles")
            .select()
            .in("role", values: ["case_manager","therapist","counselor"])
            .eq("status", value: "active")
        if let facility {
            query = query.eq("admin_facility", value: facility.rawValue)
        }
        let users: [User] = try await query
            .order("full_name", ascending: true)
            .execute()
            .value
        return users
    }

    nonisolated private struct StaffAssignmentRow: Decodable {
        let userId: UUID
        let staffId: UUID
        enum CodingKeys: String, CodingKey {
            case userId
            case staffId
        }
    }

    func fetchStaffAssignments() async throws -> [(userId: UUID, staffId: UUID)] {
        let rows: [StaffAssignmentRow] = try await client.from("staff_assignments")
            .select("user_id, staff_id")
            .execute()
            .value
        return rows.map { ($0.userId, $0.staffId) }
    }

    // MARK: - Admin: Notifications

    nonisolated private struct SobrietyLogRow: Decodable {
        let id: UUID
        let userId: UUID
        let previousDate: Date?
        let newDate: Date
        let changedAt: Date
        let isReset: Bool
        let userProfile: NestedProfile
        struct NestedProfile: Decodable {
            let fullName: String
            let facility: String?
            enum CodingKeys: String, CodingKey {
                case fullName
                case facility
            }
        }
        enum CodingKeys: String, CodingKey {
            case id, userId = "user_id"
            case previousDate
            case newDate
            case changedAt
            case isReset
            case userProfile = "user_profile:profiles!user_id"
        }
    }

    func fetchSobrietyChanges(since: Date, facility: Facility?) async throws -> [SobrietyChangeRow] {
        let formatter = ISO8601DateFormatter()
        let rows: [SobrietyLogRow] = try await client.from("sobriety_change_log")
            .select("id, user_id, previous_date, new_date, changed_at, is_reset, user_profile:profiles!user_id(full_name, facility)")
            .gte("changed_at", value: formatter.string(from: since))
            .order("changed_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return rows
            .filter { facility == nil || $0.userProfile.facility == facility?.rawValue }
            .map {
                SobrietyChangeRow(
                    id: $0.id,
                    userId: $0.userId,
                    userName: $0.userProfile.fullName,
                    previousDate: $0.previousDate,
                    newDate: $0.newDate,
                    changedAt: $0.changedAt,
                    isReset: $0.isReset
                )
            }
    }

    nonisolated private struct BadgeAwardLogRow: Decodable {
        let id: UUID
        let userId: UUID
        let badgeId: UUID
        let earnedAt: Date
        let userProfile: BProfile
        let badge: BBadge
        struct BProfile: Decodable {
            let fullName: String
            let facility: String?
            enum CodingKeys: String, CodingKey {
                case fullName
                case facility
            }
        }
        struct BBadge: Decodable {
            let name: String
            let emoji: String
        }
        enum CodingKeys: String, CodingKey {
            case id
            case userId
            case badgeId
            case earnedAt
            case userProfile = "user_profile:profiles!user_id"
            case badge = "badge:badges!badge_id"
        }
    }

    func fetchRecentBadgeAwards(limit: Int, facility: Facility?) async throws -> [BadgeAwardRow] {
        let rows: [BadgeAwardLogRow] = try await client.from("user_badges")
            .select("id, user_id, badge_id, earned_at, user_profile:profiles!user_id(full_name, facility), badge:badges!badge_id(name, emoji)")
            .order("earned_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows
            .filter { facility == nil || $0.userProfile.facility == facility?.rawValue }
            .map {
                BadgeAwardRow(
                    id: $0.id,
                    userId: $0.userId,
                    userName: $0.userProfile.fullName,
                    badgeId: $0.badgeId,
                    badgeName: $0.badge.name,
                    badgeEmoji: $0.badge.emoji,
                    earnedAt: $0.earnedAt
                )
            }
    }

    func fetchFlaggedMessages(limit: Int, facility: Facility?) async throws -> [ChatMessage] {
        // Status values MUST match the MessageModerationStatus raw values that
        // actually get written: "flagged_for_crisis" (crisis), "flagged",
        // "pending", "pending_review". The old list ["flagged","crisis"] never
        // matched "flagged_for_crisis", so the admin Chat Monitor showed NO
        // flagged patient messages — a safety-critical miss.
        let messages: [ChatMessage] = try await client.from("messages")
            .select()
            .in("status", values: ["flagged_for_crisis", "flagged", "pending", "pending_review"])
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return messages
    }

    // MARK: - Invite

    /// Invite a prospective member by EMAIL (v1 uses email, not SMS).
    func sendInvite(email: String, name: String?) async throws -> String {
        let params = InviteEmailParams(to: email, name: name)
        let response: InviteEmailResponse = try await client.functions.invoke(
            "send-invite-email",
            options: .init(
                method: .post,
                body: params
            )
        )

        if let error = response.error {
            throw NSError(domain: "invite", code: 500, userInfo: [NSLocalizedDescriptionKey: error])
        }
        if response.sent == false, let reason = response.reason {
            throw NSError(domain: "invite", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Invite not sent (\(reason))."])
        }

        return response.email ?? email
    }

    // MARK: - Block & Report (Apple Guideline 1.2 — UGC safety)

    func blockUser(_ userId: UUID) async throws {
        let blockerId = try await currentUserId
        // No-op if the user somehow tries to block themselves.
        guard userId != blockerId else { return }

        let insert = BlockInsertParams(
            blockerId: blockerId.uuidString,
            blockedId: userId.uuidString
        )
        // Upsert-style: ignore duplicate-block races. RLS scopes rows to the
        // blocker, so this can only ever write the current user's own block.
        try await client.from("blocked_users")
            .insert(insert)
            .execute()

        // Refresh the per-session cache so feeds filter immediately.
        blockedUserIdsCache = nil
        _ = await blockedUserIds()
    }

    func unblockUser(_ userId: UUID) async throws {
        let blockerId = try await currentUserId
        try await client.from("blocked_users")
            .delete()
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: userId.uuidString)
            .execute()

        blockedUserIdsCache = nil
        _ = await blockedUserIds()
    }

    func fetchBlockedUserIds() async throws -> Set<UUID> {
        let blockerId = try await currentUserId
        let rows: [BlockedRow] = try await client.from("blocked_users")
            .select("blocked_id")
            .eq("blocker_id", value: blockerId.uuidString)
            .execute()
            .value
        let set = Set(rows.map(\.blockedId))
        blockedUserIdsCache = set
        return set
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        let ids = try await fetchBlockedUserIds()
        guard !ids.isEmpty else { return [] }

        // Resolve display names from profiles. If a name can't be resolved
        // (deleted profile, RLS), fall back to a generic label so the row still
        // shows and can be unblocked.
        let profiles: [BlockedProfileRow] = (try? await client.from("profiles")
            .select("id, username, full_name")
            .in("id", values: ids.map(\.uuidString))
            .execute()
            .value) ?? []

        let nameById = Dictionary(uniqueKeysWithValues: profiles.map {
            ($0.id, $0.username ?? $0.fullName ?? "Blocked user")
        })

        return ids
            .map { BlockedUser(id: $0, displayName: nameById[$0] ?? "Blocked user") }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func reportPost(_ postId: UUID, reason: String?) async throws {
        let reporterId = try? await currentUserId
        try await ContentFilterService.shared.reportUserContent(
            kind: "post",
            targetId: postId,
            reporterId: reporterId,
            reason: reason
        )
    }

    func reportComment(_ commentId: UUID, reason: String?) async throws {
        let reporterId = try? await currentUserId
        try await ContentFilterService.shared.reportUserContent(
            kind: "comment",
            targetId: commentId,
            reporterId: reporterId,
            reason: reason
        )
    }

    // MARK: - Data Export (HIPAA Right of Access)

    /// Fetch everything the current user authored — posts, comments, and chat
    /// messages they sent — for the Settings → "Download My Data" export.
    /// Scoped to the caller's own rows via `user_id` / `sender_id` filters
    /// (RLS enforces the same boundary server-side — defense in depth).
    func fetchMyContentForExport() async throws -> UserContentExport {
        let userId = try await currentUserId

        let postRows: [ExportPostRow] = try await client.from("posts")
            .select("content, category, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        let commentRows: [ExportCommentRow] = try await client.from("comments")
            .select("content, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        let messageRows: [ExportMessageRow] = try await client.from("messages")
            .select("content, created_at")
            .eq("sender_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        return UserContentExport(
            posts: postRows.map {
                UserContentExport.ExportPost(content: $0.content, category: $0.category, createdAt: $0.createdAt)
            },
            comments: commentRows.map {
                UserContentExport.ExportComment(content: $0.content, createdAt: $0.createdAt)
            },
            messages: messageRows.map {
                UserContentExport.ExportMessage(content: $0.content ?? "", createdAt: $0.createdAt)
            }
        )
    }

    // MARK: - Telehealth Appointments

    func fetchAppointments() async throws -> [Appointment] {
        // RLS scopes visibility (own-as-client / own-as-provider / facility staff).
        // client_id and provider_id are real FKs to profiles, so PostgREST can
        // embed each name (disambiguated by the FK column). A name comes back
        // nil only if profile-read RLS blocks it; the UI falls back gracefully.
        let rows: [AppointmentRow] = try await client.from("appointments")
            .select("*, client:profiles!client_id(full_name), provider:profiles!provider_id(full_name)")
            .order("scheduled_start", ascending: true)
            .execute()
            .value
        return rows.map { $0.toAppointment() }
    }

    func createAppointment(_ appointment: Appointment) async throws -> Appointment {
        let insert = AppointmentInsert(from: appointment)
        let created: Appointment = try await client.from("appointments")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return created
    }

    func updateAppointment(_ appointment: Appointment) async throws -> Appointment {
        let update = AppointmentUpdate(from: appointment)
        let updated: Appointment = try await client.from("appointments")
            .update(update)
            .eq("id", value: appointment.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }

    func submitAppointmentFeedback(_ feedback: AppointmentFeedback) async throws -> AppointmentFeedback {
        let insert = AppointmentFeedbackInsert(from: feedback)
        // One reflection per session — upsert so a client can revise theirs.
        let saved: AppointmentFeedback = try await client.from("appointment_feedback")
            .upsert(insert, onConflict: "appointment_id")
            .select()
            .single()
            .execute()
            .value
        return saved
    }

    func fetchAppointmentFeedback(appointmentId: UUID) async throws -> AppointmentFeedback? {
        let rows: [AppointmentFeedback] = try await client.from("appointment_feedback")
            .select()
            .eq("appointment_id", value: appointmentId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
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

    /// Fetch the set of comment IDs (under the given post) the user has liked.
    /// We scope by post_id so we only read what's needed for the current view.
    private func fetchLikedCommentIds(userId: UUID, postId: UUID) async throws -> [UUID] {
        let rows: [CommentLikeRow] = try await client.from("comment_likes")
            .select("comment_id, comments!inner(post_id)")
            .eq("user_id", value: userId.uuidString)
            .eq("comments.post_id", value: postId.uuidString)
            .execute()
            .value

        return rows.map(\.commentId)
    }
}

// MARK: - Appointment Encode Rows

/// PostgREST's encoder does not snake_case keys, so INSERT/UPDATE bodies use
/// explicit snake_case property names (same pattern as MeetingInsertRow).
private struct AppointmentInsert: Encodable {
    let client_id: String
    let provider_id: String
    let facility: String?
    let appointment_type: String
    let purpose: String?
    let status: String
    let requested_by: String?
    let scheduled_start: String?
    let duration_minutes: Int
    let zoom_meeting_id: String?
    let zoom_join_url: String?
    let staff_note: String?
    let created_by: String?

    init(from a: Appointment) {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        client_id = a.clientId.uuidString.lowercased()
        provider_id = a.providerId.uuidString.lowercased()
        facility = a.facility?.rawValue
        appointment_type = a.appointmentType.rawValue
        purpose = a.purpose
        status = a.status.rawValue
        requested_by = a.requestedBy?.uuidString.lowercased()
        scheduled_start = a.scheduledStart.map { iso.string(from: $0) }
        duration_minutes = a.durationMinutes
        zoom_meeting_id = a.zoomMeetingId
        zoom_join_url = a.zoomJoinUrl
        staff_note = a.staffNote
        created_by = a.createdBy?.uuidString.lowercased()
    }
}

/// Mutable columns only — id, client, provider, and created_by never change.
private struct AppointmentUpdate: Encodable {
    let facility: String?
    let appointment_type: String
    let purpose: String?
    let status: String
    let scheduled_start: String?
    let duration_minutes: Int
    let zoom_meeting_id: String?
    let zoom_join_url: String?
    let staff_note: String?

    init(from a: Appointment) {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        facility = a.facility?.rawValue
        appointment_type = a.appointmentType.rawValue
        purpose = a.purpose
        status = a.status.rawValue
        scheduled_start = a.scheduledStart.map { iso.string(from: $0) }
        duration_minutes = a.durationMinutes
        zoom_meeting_id = a.zoomMeetingId
        zoom_join_url = a.zoomJoinUrl
        staff_note = a.staffNote
    }
}

private struct AppointmentFeedbackInsert: Encodable {
    let appointment_id: String
    let client_id: String
    let rating: Int?
    let reflection: String?

    init(from f: AppointmentFeedback) {
        appointment_id = f.appointmentId.uuidString.lowercased()
        client_id = f.clientId.uuidString.lowercased()
        rating = f.rating
        reflection = f.reflection
    }
}

/// Decode row for appointments, carrying the embedded client/provider names.
private struct AppointmentRow: Decodable {
    let id: UUID
    let clientId: UUID
    let providerId: UUID
    let facility: String?
    let appointmentType: String
    let purpose: String?
    let status: String
    let requestedBy: UUID?
    let scheduledStart: Date?
    let durationMinutes: Int
    let zoomMeetingId: String?
    let zoomJoinUrl: String?
    let staffNote: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date?
    let client: NameRow?
    let provider: NameRow?

    struct NameRow: Decodable { let fullName: String? }

    func toAppointment() -> Appointment {
        Appointment(
            id: id,
            clientId: clientId,
            providerId: providerId,
            facility: facility.flatMap { Facility(rawValue: $0) },
            appointmentType: AppointmentType(rawValue: appointmentType) ?? .individualTherapy,
            purpose: purpose,
            status: AppointmentStatus(rawValue: status) ?? .requested,
            requestedBy: requestedBy,
            scheduledStart: scheduledStart,
            durationMinutes: durationMinutes,
            zoomMeetingId: zoomMeetingId,
            zoomJoinUrl: zoomJoinUrl,
            staffNote: staffNote,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            clientName: client?.fullName,
            providerName: provider?.fullName
        )
    }
}
