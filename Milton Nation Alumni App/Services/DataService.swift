import Foundation

protocol DataServiceProtocol {
    // Posts
    func fetchPosts(category: PostCategory?) async throws -> [CommunityPost]
    func createPost(content: String, category: PostCategory, mediaData: Data?, mediaType: CommunityPost.MediaType?, status: PostStatus, matchedKeywords: [String]) async throws -> CommunityPost
    func toggleLike(postId: UUID) async throws -> Bool

    // Comments
    func fetchComments(postId: UUID) async throws -> [Comment]
    func addComment(postId: UUID, content: String, status: PostStatus, matchedKeywords: [String]) async throws -> Comment

    // Post Moderation (Admin)
    func fetchPendingPosts() async throws -> [CommunityPost]
    func moderatePost(postId: UUID, action: PostStatus) async throws -> CommunityPost
    func pinPost(postId: UUID, isPinned: Bool) async throws -> CommunityPost

    // Meetings
    func fetchMeetings() async throws -> [Meeting]

    // Chat
    func fetchConversations() async throws -> [Conversation]
    func fetchMessages(conversationId: UUID) async throws -> [ChatMessage]
    func sendMessage(conversationId: UUID, content: String, type: MessageType, status: MessageModerationStatus, matchedKeywords: [String]) async throws -> ChatMessage

    // User
    func fetchAssignedStaff() async throws -> [User]
    func updateProfile(user: User) async throws -> User

    // Quotes
    func fetchDailyQuote() async throws -> DailyQuote

    // Announcements
    func fetchAnnouncements() async throws -> [Announcement]
    func createAnnouncement(title: String, description: String) async throws -> Announcement
    func updateAnnouncement(id: UUID, title: String, description: String) async throws -> Announcement
    func deleteAnnouncement(id: UUID) async throws

    // Badges & Points
    func fetchBadges() async throws -> [Badge]
    func fetchUserBadges() async throws -> [UserBadge]
    func awardPoints(action: PointAction) async throws -> Int
    func checkMilestones(user: User) async throws -> SobrietyMilestone?

    // User Approval
    func fetchPendingUsers() async throws -> [User]
    func approveUser(userId: UUID) async throws -> User
    func rejectUser(userId: UUID) async throws

    // Invite
    func sendInvite(phone: String, name: String?) async throws -> String
}

final class MockDataService: DataServiceProtocol {

    private var mockPointsTotal = MockData.currentUser.totalPoints

    /// In-memory store for mock comments, keyed by post ID.
    private var mockComments: [UUID: [Comment]] = [:]

    func fetchPosts(category: PostCategory?) async throws -> [CommunityPost] {
        try await Task.sleep(for: .milliseconds(300))
        let filtered: [CommunityPost]
        if let category {
            filtered = MockData.posts.filter { $0.category == category }
        } else {
            filtered = MockData.posts
        }
        return filtered.sorted { ($0.isPinned ? 0 : 1) < ($1.isPinned ? 0 : 1) }
    }

    func createPost(content: String, category: PostCategory, mediaData: Data? = nil, mediaType: CommunityPost.MediaType? = nil, status: PostStatus = .pending, matchedKeywords: [String] = []) async throws -> CommunityPost {
        try await Task.sleep(for: .milliseconds(300))
        return CommunityPost(
            id: UUID(), userId: MockData.currentUser.id,
            userName: MockData.currentUser.username,
            userPhotoURL: nil, category: category,
            content: content,
            mediaURL: mediaData != nil ? "mock://media/\(UUID().uuidString)" : nil,
            mediaType: mediaType,
            status: status, isPinned: false, likesCount: 0, commentsCount: 0,
            isLikedByCurrentUser: false, matchedKeywords: matchedKeywords,
            createdAt: Date(), approvedAt: status == .approved ? Date() : nil
        )
    }

    func toggleLike(postId: UUID) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(100))
        return true
    }

    // MARK: - Comments

    func fetchComments(postId: UUID) async throws -> [Comment] {
        try await Task.sleep(for: .milliseconds(200))

        // Seed sample comments on first fetch for known mock posts
        if mockComments[postId] == nil, let post = MockData.posts.first(where: { $0.id == postId }) {
            mockComments[postId] = Self.seedComments(for: post)
        }

        return (mockComments[postId] ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    func addComment(postId: UUID, content: String, status: PostStatus = .approved, matchedKeywords: [String] = []) async throws -> Comment {
        try await Task.sleep(for: .milliseconds(200))
        let comment = Comment(
            id: UUID(),
            postId: postId,
            userId: MockData.currentUser.id,
            userName: MockData.currentUser.username,
            userPhotoURL: nil,
            content: content,
            matchedKeywords: matchedKeywords,
            status: status,
            createdAt: Date()
        )
        mockComments[postId, default: []].append(comment)
        return comment
    }

    /// Generate a handful of seed comments so the UI isn't empty.
    private static func seedComments(for post: CommunityPost) -> [Comment] {
        let names = ["phoenix_rising", "grateful_heart", "helping_hand", "stronger_today"]
        let bodies = [
            "So proud of you! Keep going!",
            "This really resonated with me. Thank you for sharing.",
            "You inspire me every day. Stay strong!",
        ]
        return bodies.enumerated().map { index, body in
            Comment(
                id: UUID(),
                postId: post.id,
                userId: UUID(),
                userName: names[index % names.count],
                userPhotoURL: nil,
                content: body,
                status: .approved,
                createdAt: Calendar.current.date(byAdding: .minute, value: -(30 * (bodies.count - index)), to: Date())!
            )
        }
    }

    // MARK: - Post Moderation (Admin)

    func fetchPendingPosts() async throws -> [CommunityPost] {
        try await Task.sleep(for: .milliseconds(300))
        return MockData.posts.filter {
            $0.status == .pending || $0.status == .pendingReview || $0.status == .flaggedForCrisis
        }
    }

    func moderatePost(postId: UUID, action: PostStatus) async throws -> CommunityPost {
        try await Task.sleep(for: .milliseconds(200))
        guard var post = MockData.posts.first(where: { $0.id == postId }) else {
            throw NSError(domain: "data", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        post.status = action
        if action == .approved { post.approvedAt = Date() }
        return post
    }

    func pinPost(postId: UUID, isPinned: Bool) async throws -> CommunityPost {
        try await Task.sleep(for: .milliseconds(200))
        guard var post = MockData.posts.first(where: { $0.id == postId }) else {
            throw NSError(domain: "data", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        post.isPinned = isPinned
        return post
    }

    func fetchMeetings() async throws -> [Meeting] {
        try await Task.sleep(for: .milliseconds(300))
        return MockData.meetings
    }

    func fetchConversations() async throws -> [Conversation] {
        try await Task.sleep(for: .milliseconds(300))
        return MockData.conversations
    }

    func fetchMessages(conversationId: UUID) async throws -> [ChatMessage] {
        try await Task.sleep(for: .milliseconds(300))
        return MockData.sampleMessages.filter { $0.conversationId == conversationId }
    }

    func sendMessage(conversationId: UUID, content: String, type: MessageType, status: MessageModerationStatus = .clean, matchedKeywords: [String] = []) async throws -> ChatMessage {
        try await Task.sleep(for: .milliseconds(200))
        return ChatMessage(
            id: UUID(), conversationId: conversationId,
            senderId: MockData.currentUser.id, messageType: type,
            content: content,
            mediaURL: type != .text ? "mock://media/\(UUID().uuidString)" : nil,
            fileName: type == .file ? "attachment" : nil,
            status: status, matchedKeywords: matchedKeywords,
            createdAt: Date(), isFromCurrentUser: true
        )
    }

    func fetchAssignedStaff() async throws -> [User] {
        try await Task.sleep(for: .milliseconds(200))
        return [MockData.caseManager, MockData.therapist]
    }

    func updateProfile(user: User) async throws -> User {
        try await Task.sleep(for: .milliseconds(300))
        return user
    }

    func fetchDailyQuote() async throws -> DailyQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % MockData.quotes.count
        return MockData.quotes[index]
    }

    func fetchAnnouncements() async throws -> [Announcement] {
        try await Task.sleep(for: .milliseconds(200))
        return MockData.announcements
    }

    func createAnnouncement(title: String, description: String) async throws -> Announcement {
        try await Task.sleep(for: .milliseconds(300))
        let announcement = Announcement(id: UUID(), title: title, description: description, createdAt: Date())
        MockData.announcements.insert(announcement, at: 0)
        return announcement
    }

    func updateAnnouncement(id: UUID, title: String, description: String) async throws -> Announcement {
        try await Task.sleep(for: .milliseconds(300))
        if let index = MockData.announcements.firstIndex(where: { $0.id == id }) {
            MockData.announcements[index].title = title
            MockData.announcements[index].description = description
            return MockData.announcements[index]
        }
        throw NSError(domain: "data", code: 404, userInfo: [NSLocalizedDescriptionKey: "Announcement not found"])
    }

    func deleteAnnouncement(id: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
        MockData.announcements.removeAll { $0.id == id }
    }

    func fetchBadges() async throws -> [Badge] {
        return MockData.badges
    }

    func fetchUserBadges() async throws -> [UserBadge] {
        try await Task.sleep(for: .milliseconds(200))
        let earnedBadges = MockData.badges.filter { $0.pointsRequired <= mockPointsTotal }
        return earnedBadges.map { badge in
            UserBadge(id: UUID(), userId: MockData.currentUser.id, badgeId: badge.id, earnedAt: Date())
        }
    }

    // MARK: - Points & Milestones

    func awardPoints(action: PointAction) async throws -> Int {
        try await Task.sleep(for: .milliseconds(100))
        mockPointsTotal += action.points
        return mockPointsTotal
    }

    func checkMilestones(user: User) async throws -> SobrietyMilestone? {
        try await Task.sleep(for: .milliseconds(100))
        let days = user.daysOfRecovery
        let milestoneType: SobrietyMilestone.MilestoneType?
        switch days {
        case 30: milestoneType = .thirtyDays
        case 60: milestoneType = .sixtyDays
        case 90: milestoneType = .ninetyDays
        case 180: milestoneType = .sixMonths
        case 365: milestoneType = .oneYear
        default:
            if days > 365 && days % 365 == 0 { milestoneType = .yearly }
            else { milestoneType = nil }
        }
        guard let type = milestoneType else { return nil }
        return SobrietyMilestone(
            id: UUID(), userId: user.id,
            milestoneType: type, milestoneDate: Date(),
            pointsAwarded: type.points, createdAt: Date()
        )
    }

    // MARK: - User Approval

    func fetchPendingUsers() async throws -> [User] {
        try await Task.sleep(for: .milliseconds(200))
        return MockDataService.mockPendingUsers
    }

    func approveUser(userId: UUID) async throws -> User {
        try await Task.sleep(for: .milliseconds(300))
        guard var user = MockDataService.mockPendingUsers.first(where: { $0.id == userId }) else {
            throw NSError(domain: "data", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        user.status = .active
        MockDataService.mockPendingUsers.removeAll { $0.id == userId }
        return user
    }

    func rejectUser(userId: UUID) async throws {
        try await Task.sleep(for: .milliseconds(300))
        MockDataService.mockPendingUsers.removeAll { $0.id == userId }
    }

    // MARK: - Invite

    func sendInvite(phone: String, name: String?) async throws -> String {
        try await Task.sleep(for: .milliseconds(500))
        // Return a masked phone number like the Edge Function does
        let digits = phone.filter(\.isNumber)
        let lastFour = String(digits.suffix(4))
        let masked = String(repeating: "*", count: max(0, digits.count - 4)) + lastFour
        return masked
    }

    // Mock pending users for testing
    static var mockPendingUsers: [User] = [
        User(
            id: UUID(),
            email: "new.alumni1@email.com",
            phone: "(555) 111-2222",
            fullName: "Jordan Mitchell",
            username: "recovery_jordan",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            recoveryProgram: "IOP (Intensive Outpatient)",
            role: .alumni,
            status: .pending,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            updatedAt: Date()
        ),
        User(
            id: UUID(),
            email: "new.alumni2@email.com",
            phone: "(555) 333-4444",
            fullName: "Casey Rivera",
            username: "fresh_start_casey",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
            recoveryProgram: "Residential",
            role: .alumni,
            status: .pending,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
            updatedAt: Date()
        ),
    ]
}
