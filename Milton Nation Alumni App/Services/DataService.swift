import Foundation

protocol DataServiceProtocol {
    // Posts
    func fetchPosts(category: PostCategory?) async throws -> [CommunityPost]
    func createPost(content: String, category: PostCategory, mediaData: Data?, mediaType: CommunityPost.MediaType?, status: PostStatus, matchedKeywords: [String]) async throws -> CommunityPost
    func toggleLike(postId: UUID) async throws -> Bool
    /// Permanently remove a post the current user owns.
    /// The backend should enforce ownership via RLS.
    func deletePost(postId: UUID) async throws

    // Comments
    func fetchComments(postId: UUID) async throws -> [Comment]
    func addComment(postId: UUID, content: String, status: PostStatus, matchedKeywords: [String]) async throws -> Comment

    // Post Moderation (Admin)
    func fetchPendingPosts() async throws -> [CommunityPost]
    func moderatePost(postId: UUID, action: PostStatus) async throws -> CommunityPost
    func pinPost(postId: UUID, isPinned: Bool) async throws -> CommunityPost

    // Meetings
    func fetchMeetings() async throws -> [Meeting]
    func createMeeting(_ meeting: Meeting) async throws -> Meeting
    func updateMeeting(_ meeting: Meeting) async throws -> Meeting
    func deleteMeeting(meetingId: UUID) async throws

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
    func fetchPendingUsers(facilityFilter: Facility?) async throws -> [User]
    func approveUser(userId: UUID, facility: Facility) async throws -> User
    func rejectUser(userId: UUID) async throws

    // Admin: roster & assignments
    func fetchAlumniUsers(facility: Facility?) async throws -> [User]
    func fetchStaffMembers(facility: Facility?) async throws -> [User]
    func fetchStaffAssignments() async throws -> [(userId: UUID, staffId: UUID)]

    // Admin: notifications
    func fetchSobrietyChanges(since: Date, facility: Facility?) async throws -> [SobrietyChangeRow]
    func fetchRecentBadgeAwards(limit: Int, facility: Facility?) async throws -> [BadgeAwardRow]
    func fetchFlaggedMessages(limit: Int, facility: Facility?) async throws -> [ChatMessage]

    // Invite
    func sendInvite(phone: String, name: String?) async throws -> String
}

// MARK: - Admin Notification DTOs

/// Lightweight DTO for sobriety_change_log rows joined with profile name.
struct SobrietyChangeRow: Sendable, Identifiable {
    let id: UUID
    let userId: UUID
    let userName: String
    let previousDate: Date?
    let newDate: Date
    let changedAt: Date
    let isReset: Bool
}

/// Lightweight DTO for recent badge awards from user_badges joined with profile + badge.
struct BadgeAwardRow: Sendable, Identifiable {
    let id: UUID
    let userId: UUID
    let userName: String
    let badgeId: UUID
    let badgeName: String
    let badgeEmoji: String
    let earnedAt: Date
}

final class MockDataService: DataServiceProtocol {

    private var mockPointsTotal = MockData.currentUser.totalPoints

    /// In-memory store for mock comments, keyed by post ID.
    private var mockComments: [UUID: [Comment]] = [:]

    /// In-memory persistence for the session — so TestFlight/Dev users actually
    /// see their changes survive within a single app run. Without this, every
    /// "create post", "send message", "update profile" call returned its input
    /// but never appended anywhere, so the screens would refetch the static
    /// MockData and the change "disappeared".
    private var mockUserOverride: User?
    private var mockPostsAppended: [CommunityPost] = []
    private var mockMessagesAppended: [UUID: [ChatMessage]] = [:]
    private var mockProfilePhotoURLByUserId: [UUID: String] = [:]

    /// The current user state, with any in-session profile mutations applied.
    private var currentMockUser: User {
        var u = mockUserOverride ?? MockData.currentUser
        if let photoURL = mockProfilePhotoURLByUserId[u.id] {
            u.profilePhotoURL = photoURL
        }
        return u
    }

    func fetchPosts(category: PostCategory?) async throws -> [CommunityPost] {
        try await Task.sleep(for: .milliseconds(300))
        // Combine the static seed posts with any posts created in this session,
        // so a post the user just created shows up in the feed without needing
        // a real backend.
        let all = mockPostsAppended + MockData.posts
        let filtered: [CommunityPost]
        if let category {
            filtered = all.filter { $0.category == category }
        } else {
            filtered = all
        }
        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func createPost(content: String, category: PostCategory, mediaData: Data? = nil, mediaType: CommunityPost.MediaType? = nil, status: PostStatus = .pending, matchedKeywords: [String] = []) async throws -> CommunityPost {
        try await Task.sleep(for: .milliseconds(300))
        let me = currentMockUser
        // In mock mode, posts skip moderation — show them in the feed immediately
        // so the user sees their post appear. Real backend respects `status`.
        let effectiveStatus: PostStatus = status == .pending ? .approved : status
        let post = CommunityPost(
            id: UUID(),
            userId: me.id,
            userName: me.username,
            userPhotoURL: me.profilePhotoURL,
            category: category,
            content: content,
            mediaURL: mediaData != nil ? "mock://media/\(UUID().uuidString)" : nil,
            mediaType: mediaType,
            status: effectiveStatus,
            isPinned: false,
            likesCount: 0,
            commentsCount: 0,
            matchedKeywords: matchedKeywords,
            createdAt: Date(),
            approvedAt: effectiveStatus == .approved ? Date() : nil
        )
        // Prepend so it appears at the top of the feed immediately
        mockPostsAppended.insert(post, at: 0)
        return post
    }

    func toggleLike(postId: UUID) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(100))
        return true
    }

    func deletePost(postId: UUID) async throws {
        try await Task.sleep(for: .milliseconds(150))
        // Remove from any in-session appended posts (mock mode)
        mockPostsAppended.removeAll { $0.id == postId }
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

    /// Seed a handful of mock comments so the UI isn't empty.
    /// Per user request, all mock comments simply read "test test test"
    /// so the TestFlight build clearly shows mock content vs. real content.
    private static func seedComments(for post: CommunityPost) -> [Comment] {
        let names = ["test_commenter_a", "test_commenter_b", "test_commenter_c"]
        return names.enumerated().map { index, name in
            Comment(
                id: UUID(),
                postId: post.id,
                userId: UUID(),
                userName: name,
                userPhotoURL: nil,
                content: "test test test",
                status: .approved,
                createdAt: Calendar.current.date(byAdding: .minute, value: -(30 * (names.count - index)), to: Date()) ?? Date()
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

    func createMeeting(_ meeting: Meeting) async throws -> Meeting {
        try await Task.sleep(for: .milliseconds(200))
        return meeting
    }

    func updateMeeting(_ meeting: Meeting) async throws -> Meeting {
        try await Task.sleep(for: .milliseconds(200))
        return meeting
    }

    func deleteMeeting(meetingId: UUID) async throws {
        try await Task.sleep(for: .milliseconds(150))
    }

    func fetchConversations() async throws -> [Conversation] {
        try await Task.sleep(for: .milliseconds(300))
        return MockData.conversations
    }

    func fetchMessages(conversationId: UUID) async throws -> [ChatMessage] {
        try await Task.sleep(for: .milliseconds(300))
        // Combine seed messages with any messages sent in this session so the
        // user's just-typed message survives navigating away + back.
        let seeded = MockData.sampleMessages.filter { $0.conversationId == conversationId }
        let appended = mockMessagesAppended[conversationId] ?? []
        return (seeded + appended).sorted { $0.createdAt < $1.createdAt }
    }

    func sendMessage(conversationId: UUID, content: String, type: MessageType, status: MessageModerationStatus = .clean, matchedKeywords: [String] = []) async throws -> ChatMessage {
        try await Task.sleep(for: .milliseconds(200))
        let me = currentMockUser
        let message = ChatMessage(
            id: UUID(),
            conversationId: conversationId,
            senderId: me.id,
            messageType: type,
            content: content,
            mediaURL: type != .text ? "mock://media/\(UUID().uuidString)" : nil,
            fileName: type == .file ? "attachment" : nil,
            status: status,
            matchedKeywords: matchedKeywords,
            createdAt: Date(),
            isFromCurrentUser: true
        )
        // Persist in-session so the message survives navigating away + back
        mockMessagesAppended[conversationId, default: []].append(message)
        return message
    }

    func fetchAssignedStaff() async throws -> [User] {
        try await Task.sleep(for: .milliseconds(200))
        return [MockData.caseManager, MockData.therapist]
    }

    func updateProfile(user: User) async throws -> User {
        try await Task.sleep(for: .milliseconds(300))
        // Persist in-session so sobriety date, profile photo, etc. survive
        // navigating away + back in dev/TestFlight (mock) mode.
        mockUserOverride = user
        if let url = user.profilePhotoURL, !url.isEmpty {
            mockProfilePhotoURLByUserId[user.id] = url
        }
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

    func fetchPendingUsers(facilityFilter: Facility?) async throws -> [User] {
        try await Task.sleep(for: .milliseconds(200))
        guard let filter = facilityFilter else { return MockDataService.mockPendingUsers }
        return MockDataService.mockPendingUsers.filter { $0.facility == filter }
    }

    func approveUser(userId: UUID, facility: Facility) async throws -> User {
        try await Task.sleep(for: .milliseconds(300))
        guard var user = MockDataService.mockPendingUsers.first(where: { $0.id == userId }) else {
            throw NSError(domain: "data", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        user.status = .active
        user.facility = facility
        MockDataService.mockPendingUsers.removeAll { $0.id == userId }
        return user
    }

    func rejectUser(userId: UUID) async throws {
        try await Task.sleep(for: .milliseconds(300))
        MockDataService.mockPendingUsers.removeAll { $0.id == userId }
    }

    // MARK: - Admin: roster & assignments

    func fetchAlumniUsers(facility: Facility?) async throws -> [User] {
        try await Task.sleep(for: .milliseconds(200))
        var users = MockData.alumniRoster
        if let facility {
            users = users.filter { $0.facility == facility }
        }
        return users
    }

    func fetchStaffMembers(facility: Facility?) async throws -> [User] {
        try await Task.sleep(for: .milliseconds(200))
        return [MockData.caseManager, MockData.therapist]
    }

    func fetchStaffAssignments() async throws -> [(userId: UUID, staffId: UUID)] {
        try await Task.sleep(for: .milliseconds(200))
        return MockData.staffAssignments.map { ($0.userId, $0.staffId) }
    }

    // MARK: - Admin: notifications (mock returns sample rows)

    func fetchSobrietyChanges(since: Date, facility: Facility?) async throws -> [SobrietyChangeRow] {
        try await Task.sleep(for: .milliseconds(200))
        let now = Date()
        return [
            SobrietyChangeRow(
                id: UUID(),
                userId: MockData.alumniRoster[0].id,
                userName: MockData.alumniRoster[0].fullName,
                previousDate: Calendar.current.date(byAdding: .day, value: -365, to: now),
                newDate: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                changedAt: Calendar.current.date(byAdding: .hour, value: -6, to: now) ?? now,
                isReset: true
            )
        ]
    }

    func fetchRecentBadgeAwards(limit: Int, facility: Facility?) async throws -> [BadgeAwardRow] {
        try await Task.sleep(for: .milliseconds(200))
        let now = Date()
        return MockData.badges.prefix(min(limit, 3)).enumerated().map { idx, badge in
            BadgeAwardRow(
                id: UUID(),
                userId: MockData.alumniRoster[idx % MockData.alumniRoster.count].id,
                userName: MockData.alumniRoster[idx % MockData.alumniRoster.count].fullName,
                badgeId: badge.id,
                badgeName: badge.name,
                badgeEmoji: badge.emoji,
                earnedAt: Calendar.current.date(byAdding: .hour, value: -idx * 4, to: now) ?? now
            )
        }
    }

    func fetchFlaggedMessages(limit: Int, facility: Facility?) async throws -> [ChatMessage] {
        try await Task.sleep(for: .milliseconds(200))
        return []
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
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
            dischargeDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            recoveryProgram: "IOP (Intensive Outpatient)",
            role: .alumni,
            status: .pending,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            updatedAt: Date()
        ),
        User(
            id: UUID(),
            email: "new.alumni2@email.com",
            phone: "(555) 333-4444",
            fullName: "Casey Rivera",
            username: "fresh_start_casey",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date(),
            dischargeDate: Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date(),
            recoveryProgram: "Residential",
            role: .alumni,
            status: .pending,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            updatedAt: Date()
        ),
    ]
}

// MARK: - Meeting Service Protocol

/// Focused protocol for Milton-organized meeting CRUD.
/// Used by MeetingsViewModel — separate from the broader DataServiceProtocol.
protocol MeetingServiceProtocol: Sendable {
    func fetchMeetings() async throws -> [Meeting]
    func createMeeting(_ meeting: Meeting) async throws -> Meeting
    func updateMeeting(_ meeting: Meeting) async throws -> Meeting
    func deleteMeeting(meetingId: UUID) async throws
}

// MARK: - Mock Meeting Service

final class MockMeetingService: MeetingServiceProtocol {
    private var meetings: [Meeting] = MockData.meetings

    func fetchMeetings() async throws -> [Meeting] {
        try await Task.sleep(for: .milliseconds(300))
        return meetings.sorted { $0.startTime < $1.startTime }
    }

    func createMeeting(_ meeting: Meeting) async throws -> Meeting {
        try await Task.sleep(for: .milliseconds(300))
        meetings.append(meeting)
        return meeting
    }

    func updateMeeting(_ meeting: Meeting) async throws -> Meeting {
        try await Task.sleep(for: .milliseconds(300))
        if let idx = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[idx] = meeting
        }
        return meeting
    }

    func deleteMeeting(meetingId: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
        meetings.removeAll { $0.id == meetingId }
    }
}
