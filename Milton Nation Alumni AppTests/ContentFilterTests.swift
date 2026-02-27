import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("Content Filter Tests")
struct ContentFilterTests {

    let service = ContentFilterService.shared

    // MARK: - Local Filter — Clean Content

    @Test("Clean text returns clean status")
    func cleanTextReturnsClean() {
        let result = service.localFilter("Having a great day today!")
        #expect(result.status == .clean)
        #expect(result.matchedKeywords.isEmpty)
        #expect(!result.isCrisis)
        #expect(!result.isFlagged)
    }

    @Test("Empty text returns clean status")
    func emptyTextReturnsClean() {
        let result = service.localFilter("")
        #expect(result.status == .clean)
        #expect(result.matchedKeywords.isEmpty)
    }

    @Test("Normal recovery discussion returns clean")
    func normalRecoveryDiscussionClean() {
        let result = service.localFilter("Grateful for my support group. Meeting was helpful today.")
        #expect(result.status == .clean)
    }

    // MARK: - Local Filter — Flagged Content

    @Test("Substance reference triggers flagged status")
    func substanceReferenceFlagged() {
        let result = service.localFilter("I relapsed last night and feel terrible")
        #expect(result.status == .flagged)
        #expect(result.matchedKeywords.contains("relapsed"))
    }

    @Test("Self-harm language triggers flagged status")
    func selfHarmLanguageFlagged() {
        let result = service.localFilter("I've been cutting again and can't stop")
        #expect(result.status == .flagged)
        #expect(result.matchedKeywords.contains("cutting"))
    }

    @Test("Case insensitive keyword matching")
    func caseInsensitiveMatching() {
        let result = service.localFilter("I RELAPSED yesterday")
        #expect(result.status == .flagged)
        #expect(result.matchedKeywords.contains("relapsed"))
    }

    @Test("Multiple flagged keywords detected")
    func multipleFlaggedKeywords() {
        let result = service.localFilter("I fell off the wagon and started drinking again, feeling hopeless")
        #expect(result.status == .flagged)
        #expect(result.matchedKeywords.count >= 2)
    }

    // MARK: - Local Filter — Crisis Content

    @Test("Suicidal ideation triggers crisis status")
    func suicidalIdeationCrisis() {
        let result = service.localFilter("I want to die, nothing matters anymore")
        #expect(result.status == .crisis)
        #expect(result.isCrisis)
        #expect(result.matchedKeywords.contains("want to die"))
    }

    @Test("Overdose reference triggers crisis status")
    func overdoseReferenceCrisis() {
        let result = service.localFilter("I think I overdosed on something")
        #expect(result.status == .crisis)
        #expect(result.matchedKeywords.contains("overdosed"))
    }

    @Test("Emergency language triggers crisis status")
    func emergencyLanguageCrisis() {
        let result = service.localFilter("I'm not safe right now, need help now")
        #expect(result.status == .crisis)
        #expect(result.isCrisis)
    }

    @Test("Crisis takes priority over flagged keywords")
    func crisisPriorityOverFlagged() {
        // Contains both flagged ("relapsed") and crisis ("kill myself") keywords
        let result = service.localFilter("I relapsed and want to kill myself")
        #expect(result.status == .crisis)
    }

    // MARK: - Post Status Determination

    @Test("Clean content with high post count auto-approves")
    func cleanHighCountAutoApproves() {
        let result = ModerationResult(status: .clean, matchedKeywords: [])
        let status = service.postStatus(for: result, approvedPostCount: 15)
        #expect(status == .approved)
    }

    @Test("Clean content with low post count goes to pending")
    func cleanLowCountPending() {
        let result = ModerationResult(status: .clean, matchedKeywords: [])
        let status = service.postStatus(for: result, approvedPostCount: 5)
        #expect(status == .pending)
    }

    @Test("Clean content at exactly 10 posts auto-approves")
    func cleanExactThresholdApproves() {
        let result = ModerationResult(status: .clean, matchedKeywords: [])
        let status = service.postStatus(for: result, approvedPostCount: 10)
        #expect(status == .approved)
    }

    @Test("Flagged content goes to pendingReview regardless of count")
    func flaggedContentPendingReview() {
        let result = ModerationResult(status: .flagged, matchedKeywords: ["relapsed"])
        let status = service.postStatus(for: result, approvedPostCount: 100)
        #expect(status == .pendingReview)
    }

    @Test("Crisis content goes to flaggedForCrisis regardless of count")
    func crisisContentFlaggedForCrisis() {
        let result = ModerationResult(status: .crisis, matchedKeywords: ["suicide"])
        let status = service.postStatus(for: result, approvedPostCount: 100)
        #expect(status == .flaggedForCrisis)
    }

    // MARK: - Message Status Determination

    @Test("Clean message returns clean status")
    func cleanMessageStatusClean() {
        let result = ModerationResult(status: .clean, matchedKeywords: [])
        let status = service.messageStatus(for: result)
        #expect(status == .clean)
    }

    @Test("Flagged message returns flagged status")
    func flaggedMessageStatusFlagged() {
        let result = ModerationResult(status: .flagged, matchedKeywords: ["relapsed"])
        let status = service.messageStatus(for: result)
        #expect(status == .flagged)
    }

    @Test("Crisis message returns flaggedForCrisis status")
    func crisisMessageStatusFlaggedForCrisis() {
        let result = ModerationResult(status: .crisis, matchedKeywords: ["suicide"])
        let status = service.messageStatus(for: result)
        #expect(status == .flaggedForCrisis)
    }

    // MARK: - Full Pipeline (async)

    @Test("Full moderation pipeline returns correct result for clean text")
    func fullPipelineClean() async {
        let result = await service.moderateText("Beautiful day for recovery!")
        #expect(result.status == .clean)
        #expect(result.matchedKeywords.isEmpty)
    }

    @Test("Full moderation pipeline returns correct result for flagged text")
    func fullPipelineFlagged() async {
        let result = await service.moderateText("I relapsed last weekend")
        #expect(result.status == .flagged)
        #expect(!result.matchedKeywords.isEmpty)
    }

    @Test("Full moderation pipeline returns correct result for crisis text")
    func fullPipelineCrisis() async {
        let result = await service.moderateText("I want to end it all tonight")
        #expect(result.status == .crisis)
        #expect(result.isCrisis)
    }

    // MARK: - Keyword Lists Validation

    @Test("Flagged keywords list is not empty")
    func flaggedKeywordsNotEmpty() {
        #expect(!ModerationKeywords.flagged.isEmpty)
    }

    @Test("Crisis keywords list is not empty")
    func crisisKeywordsNotEmpty() {
        #expect(!ModerationKeywords.crisis.isEmpty)
    }

    @Test("Crisis keywords are distinct from flagged keywords")
    func crisisAndFlaggedDistinct() {
        let flaggedSet = Set(ModerationKeywords.flagged)
        let crisisSet = Set(ModerationKeywords.crisis)
        // Crisis keywords should NOT overlap with flagged keywords
        #expect(flaggedSet.intersection(crisisSet).isEmpty)
    }

    // MARK: - Model Updates

    @Test("PostStatus has pendingReview case")
    func postStatusHasPendingReview() {
        let status = PostStatus.pendingReview
        #expect(status.rawValue == "pending_review")
    }

    @Test("PostStatus has flaggedForCrisis case")
    func postStatusHasFlaggedForCrisis() {
        let status = PostStatus.flaggedForCrisis
        #expect(status.rawValue == "flagged_for_crisis")
    }

    @Test("MessageModerationStatus has all expected cases")
    func messageModerationStatusCases() {
        let clean = MessageModerationStatus.clean
        let flagged = MessageModerationStatus.flagged
        let crisis = MessageModerationStatus.flaggedForCrisis
        #expect(clean.rawValue == "clean")
        #expect(flagged.rawValue == "flagged")
        #expect(crisis.rawValue == "flagged_for_crisis")
    }

    // MARK: - Comment Moderation Tests (Feature #6)

    @Test("Clean comment gets approved status via localFilter")
    func cleanCommentApproved() {
        let result = service.localFilter("Keep up the great work everyone!")
        #expect(result.status == .clean)
        // Clean → .approved for comments
        let commentStatus: PostStatus
        switch result.status {
        case .crisis: commentStatus = .flaggedForCrisis
        case .flagged: commentStatus = .pendingReview
        case .clean: commentStatus = .approved
        }
        #expect(commentStatus == .approved)
    }

    @Test("Flagged comment gets pendingReview status via localFilter")
    func flaggedCommentPendingReview() {
        let result = service.localFilter("I relapsed and I'm struggling today")
        #expect(result.status == .flagged)
        let commentStatus: PostStatus
        switch result.status {
        case .crisis: commentStatus = .flaggedForCrisis
        case .flagged: commentStatus = .pendingReview
        case .clean: commentStatus = .approved
        }
        #expect(commentStatus == .pendingReview)
        #expect(result.matchedKeywords.contains("relapsed"))
    }

    @Test("Crisis comment gets flaggedForCrisis status via localFilter")
    func crisisCommentFlaggedForCrisis() {
        let result = service.localFilter("I want to end it all tonight")
        #expect(result.status == .crisis)
        let commentStatus: PostStatus
        switch result.status {
        case .crisis: commentStatus = .flaggedForCrisis
        case .flagged: commentStatus = .pendingReview
        case .clean: commentStatus = .approved
        }
        #expect(commentStatus == .flaggedForCrisis)
        #expect(result.isCrisis)
    }

    @Test("CommunityPost matchedKeywords defaults to empty")
    func communityPostDefaultKeywords() {
        let post = CommunityPost(
            id: UUID(), userId: UUID(),
            userName: "test", category: .general,
            content: "test",
            status: .pending, likesCount: 0, commentsCount: 0,
            isLikedByCurrentUser: false, createdAt: Date()
        )
        #expect(post.matchedKeywords.isEmpty)
    }

    @Test("ChatMessage status defaults to clean")
    func chatMessageDefaultStatus() {
        let msg = ChatMessage(
            id: UUID(), conversationId: UUID(),
            senderId: UUID(), messageType: .text,
            content: "hello", createdAt: Date()
        )
        #expect(msg.status == .clean)
        #expect(msg.matchedKeywords.isEmpty)
    }

    @Test("User approvedPostCount defaults to 0")
    func userApprovedPostCountDefault() {
        let user = User(
            id: UUID(), email: "test@example.com",
            phone: "(555) 000-0000", fullName: "Test User",
            username: "test_user", sobrietyDate: Date(),
            dischargeDate: Date(), recoveryProgram: "Test",
            role: .alumni, status: .active, totalPoints: 0,
            createdAt: Date(), updatedAt: Date()
        )
        #expect(user.approvedPostCount == 0)
    }
}
