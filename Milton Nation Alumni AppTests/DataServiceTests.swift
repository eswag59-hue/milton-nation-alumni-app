import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("DataService Tests")
struct DataServiceTests {

    // MARK: - Points

    @Test("awardPoints adds correct amount for daily login")
    func awardPointsDailyLogin() async throws {
        let service = MockDataService()
        let total = try await service.awardPoints(action: .dailyLogin)
        // MockData.currentUser starts at 0 points, dailyLogin adds 10
        #expect(total == 10)
    }

    @Test("awardPoints accumulates across multiple calls")
    func awardPointsAccumulates() async throws {
        let service = MockDataService()
        _ = try await service.awardPoints(action: .dailyLogin) // +10
        _ = try await service.awardPoints(action: .postCreated) // +15
        let total = try await service.awardPoints(action: .postLiked) // +5
        #expect(total == 30)
    }

    @Test("PointAction has correct point values")
    func pointActionValues() {
        #expect(PointAction.dailyLogin.points == 10)
        #expect(PointAction.postCreated.points == 15)
        #expect(PointAction.postLiked.points == 5)
        #expect(PointAction.milestoneReached.points == 50)
    }

    // MARK: - Milestones

    @Test("checkMilestones returns thirtyDays at exactly 30 days")
    func checkMilestone30Days() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 30)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone?.milestoneType == .thirtyDays)
        #expect(milestone?.pointsAwarded == 50)
    }

    @Test("checkMilestones returns sixtyDays at exactly 60 days")
    func checkMilestone60Days() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 60)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone?.milestoneType == .sixtyDays)
        #expect(milestone?.pointsAwarded == 75)
    }

    @Test("checkMilestones returns ninetyDays at exactly 90 days")
    func checkMilestone90Days() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 90)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone?.milestoneType == .ninetyDays)
        #expect(milestone?.pointsAwarded == 100)
    }

    @Test("checkMilestones returns sixMonths at exactly 180 days")
    func checkMilestone180Days() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 180)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone?.milestoneType == .sixMonths)
        #expect(milestone?.pointsAwarded == 150)
    }

    @Test("checkMilestones returns oneYear at exactly 365 days")
    func checkMilestone365Days() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 365)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone?.milestoneType == .oneYear)
        #expect(milestone?.pointsAwarded == 250)
    }

    @Test("checkMilestones returns yearly at exact multiples of 365 after first year")
    func checkMilestoneYearly() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 730)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone?.milestoneType == .yearly)
    }

    @Test("checkMilestones returns nil for non-milestone days")
    func checkMilestoneNonMilestone() async throws {
        let service = MockDataService()
        let user = makeUser(sobrietyDaysAgo: 45)
        let milestone = try await service.checkMilestones(user: user)
        #expect(milestone == nil)
    }

    // MARK: - Posts

    @Test("fetchPosts returns posts")
    func fetchPostsReturns() async throws {
        let service = MockDataService()
        let posts = try await service.fetchPosts(category: nil)
        #expect(!posts.isEmpty)
    }

    @Test("fetchPosts filters by category")
    func fetchPostsFilteredByCategory() async throws {
        let service = MockDataService()
        let posts = try await service.fetchPosts(category: .wins)
        #expect(posts.allSatisfy { $0.category == .wins })
    }

    @Test("fetchPosts sorts pinned posts first")
    func fetchPostsPinnedFirst() async throws {
        let service = MockDataService()
        let posts = try await service.fetchPosts(category: nil)
        if let firstPinned = posts.firstIndex(where: { $0.isPinned }),
           let firstUnpinned = posts.firstIndex(where: { !$0.isPinned }) {
            #expect(firstPinned < firstUnpinned)
        }
    }

    @Test("createPost surfaces the post immediately in mock mode")
    func createPostPending() async throws {
        // Build 7+: MockDataService auto-approves posts created with status=.pending
        // so TestFlight/DEBUG users see their post appear in the feed immediately.
        // Real backend (SupabaseDataService) still respects the requested status.
        let service = MockDataService()
        let post = try await service.createPost(content: "Test", category: .general, mediaData: nil, mediaType: nil)
        #expect(post.status == .approved)
        #expect(post.content == "Test")
        #expect(post.category == .general)
    }

    // MARK: - Comments

    @Test("addComment returns comment with correct data")
    func addCommentReturnsCorrectData() async throws {
        let service = MockDataService()
        let postId = UUID()
        let comment = try await service.addComment(postId: postId, content: "Great post!")
        #expect(comment.content == "Great post!")
        #expect(comment.postId == postId)
    }

    @Test("addComment with status and matchedKeywords passes through correctly")
    func addCommentWithModerationFields() async throws {
        let service = MockDataService()
        let postId = UUID()
        let comment = try await service.addComment(
            postId: postId,
            content: "I relapsed last night",
            status: .pendingReview,
            matchedKeywords: ["relapsed"]
        )
        #expect(comment.content == "I relapsed last night")
        #expect(comment.status == .pendingReview)
        #expect(comment.matchedKeywords.contains("relapsed"))
    }

    @Test("addComment defaults to approved status when no status provided")
    func addCommentDefaultsApproved() async throws {
        let service = MockDataService()
        let postId = UUID()
        let comment = try await service.addComment(postId: postId, content: "Clean comment")
        #expect(comment.status == .approved)
        #expect(comment.matchedKeywords.isEmpty)
    }

    @Test("fetchComments returns added comments")
    func fetchCommentsAfterAdd() async throws {
        let service = MockDataService()
        let postId = UUID()
        _ = try await service.addComment(postId: postId, content: "Comment 1")
        _ = try await service.addComment(postId: postId, content: "Comment 2")
        let comments = try await service.fetchComments(postId: postId)
        #expect(comments.count == 2)
    }

    // MARK: - Pending Posts (Moderation)

    @Test("fetchPendingPosts returns only pending posts")
    func fetchPendingPosts() async throws {
        let service = MockDataService()
        let pending = try await service.fetchPendingPosts()
        #expect(pending.allSatisfy { $0.status == .pending })
    }

    // MARK: - Badges

    @Test("fetchBadges returns badges sorted by points required")
    func fetchBadgesReturns() async throws {
        let service = MockDataService()
        let badges = try await service.fetchBadges()
        #expect(!badges.isEmpty)
    }

    @Test("fetchUserBadges returns badges user has earned based on points")
    func fetchUserBadgesBasedOnPoints() async throws {
        let service = MockDataService()
        // Award enough points to earn at least the first badge (100 pts)
        for _ in 0..<10 {
            _ = try await service.awardPoints(action: .dailyLogin) // 10 * 10 = 100
        }
        let userBadges = try await service.fetchUserBadges()
        #expect(!userBadges.isEmpty)
    }

    // MARK: - Announcements CRUD

    @Test("createAnnouncement returns announcement with correct data")
    func createAnnouncement() async throws {
        let service = MockDataService()
        let announcement = try await service.createAnnouncement(title: "Test", description: "Test Description")
        #expect(announcement.title == "Test")
        #expect(announcement.description == "Test Description")

        // Clean up
        MockData.announcements.removeAll { $0.id == announcement.id }
    }

    @Test("deleteAnnouncement removes the created announcement")
    func deleteAnnouncement() async throws {
        let service = MockDataService()
        let announcement = try await service.createAnnouncement(title: "ToDelete", description: "Will be deleted")

        // Verify it exists
        let beforeDelete = MockData.announcements.contains { $0.id == announcement.id }
        #expect(beforeDelete == true)

        try await service.deleteAnnouncement(id: announcement.id)

        let afterDelete = MockData.announcements.contains { $0.id == announcement.id }
        #expect(afterDelete == false)
    }

    // MARK: - Daily Quote

    @Test("fetchDailyQuote returns a quote")
    func fetchDailyQuote() async throws {
        let service = MockDataService()
        let quote = try await service.fetchDailyQuote()
        #expect(!quote.text.isEmpty)
        #expect(!quote.attribution.isEmpty)
    }

    // MARK: - MilestoneType Points

    @Test("MilestoneType has correct point values")
    func milestoneTypePoints() {
        #expect(SobrietyMilestone.MilestoneType.thirtyDays.points == 50)
        #expect(SobrietyMilestone.MilestoneType.sixtyDays.points == 75)
        #expect(SobrietyMilestone.MilestoneType.ninetyDays.points == 100)
        #expect(SobrietyMilestone.MilestoneType.sixMonths.points == 150)
        #expect(SobrietyMilestone.MilestoneType.oneYear.points == 250)
        #expect(SobrietyMilestone.MilestoneType.yearly.points == 250)
    }

    // MARK: - Helpers

    private func makeUser(sobrietyDaysAgo: Int) -> User {
        User(
            id: UUID(),
            email: "test@example.com",
            phone: "(555) 000-0000",
            fullName: "Test User",
            username: "test_user",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -sobrietyDaysAgo, to: Date())!,
            dischargeDate: Date(),
            recoveryProgram: "Test",
            role: .alumni,
            status: .active,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
