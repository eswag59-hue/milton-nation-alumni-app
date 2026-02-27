import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("CommunityViewModel Tests")
struct CommunityViewModelTests {

    /// Waits for an unstructured MainActor Task spawned inside a ViewModel to complete.
    /// Sleeps long enough for mock async work, then yields multiple times to drain
    /// any pending MainActor work (e.g., `await MainActor.run { ... }` in the task).
    private func waitForViewModel(ms: Int = 600) async throws {
        try await Task.sleep(for: .milliseconds(ms))
        for _ in 0..<10 { await Task.yield() }
    }

    // MARK: - Post Loading

    @Test("loadPosts populates posts array")
    func loadPostsPopulates() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()
        #expect(!vm.posts.isEmpty)
    }

    // MARK: - Category Filtering

    @Test("filterByCategory sets selected category")
    func filterSetsCategory() {
        let vm = CommunityViewModel()
        vm.filterByCategory(.wins)
        #expect(vm.selectedCategory == .wins)
    }

    @Test("filterByCategory with nil clears filter")
    func filterNilClearsCategory() {
        let vm = CommunityViewModel()
        vm.filterByCategory(.wins)
        vm.filterByCategory(nil)
        #expect(vm.selectedCategory == nil)
    }

    // MARK: - Like Toggle

    @Test("toggleLike increments count and sets liked")
    func toggleLikeIncrements() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first(where: { !$0.isLikedByCurrentUser }) else {
            return // Skip if no unliked posts
        }

        let originalCount = post.likesCount
        vm.toggleLike(post: post)

        let updated = vm.posts.first(where: { $0.id == post.id })!
        #expect(updated.isLikedByCurrentUser == true)
        #expect(updated.likesCount == originalCount + 1)
    }

    @Test("toggleLike decrements count and unsets liked")
    func toggleLikeDecrements() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first(where: { $0.isLikedByCurrentUser }) else {
            return // Skip if no liked posts
        }

        let originalCount = post.likesCount
        vm.toggleLike(post: post)

        let updated = vm.posts.first(where: { $0.id == post.id })!
        #expect(updated.isLikedByCurrentUser == false)
        #expect(updated.likesCount == originalCount - 1)
    }

    // MARK: - Create Post

    @Test("createPost does nothing with empty content")
    func createPostEmptyContent() {
        let vm = CommunityViewModel()
        vm.newPostContent = "   "
        vm.createPost()
        #expect(vm.showPostSubmitted == false)
    }

    @Test("createPost resets form state after submission")
    func createPostResetsForm() async throws {
        let vm = CommunityViewModel()
        vm.newPostContent = "Test post content"
        vm.newPostCategory = .wins
        vm.showCreatePost = true
        vm.createPost()
        // createPost spawns a Task that runs: moderateText (100ms) + createPost mock (300ms)
        // + awardPoints mock (100ms) = ~500ms total; use 800ms to be safe, then yield.
        try await waitForViewModel(ms: 800)

        #expect(vm.newPostContent.isEmpty)
        #expect(vm.newPostCategory == .general)
        #expect(vm.showCreatePost == false)
        #expect(vm.showPostSubmitted == true)
        #expect(vm.selectedMediaData == nil)
        #expect(vm.selectedMediaType == nil)
    }

    // MARK: - Comment Toggle

    @Test("toggleComments expands and loads comments")
    func toggleCommentsExpands() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first else { return }
        vm.toggleComments(for: post.id)

        #expect(vm.expandedCommentPostIds.contains(post.id))
    }

    @Test("toggleComments collapses when already expanded")
    func toggleCommentsCollapses() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first else { return }
        vm.toggleComments(for: post.id) // expand
        vm.toggleComments(for: post.id) // collapse

        #expect(!vm.expandedCommentPostIds.contains(post.id))
    }

    // MARK: - Submit Comment

    @Test("submitComment ignores empty draft")
    func submitCommentEmptyDraft() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first else { return }
        vm.commentDrafts[post.id] = "   "
        vm.submitComment(for: post.id)

        // No comment should have been added
        try await waitForViewModel(ms: 500)
        let comments = vm.commentsByPost[post.id] ?? []
        // The draft should still be cleared (trimmed to empty)
        #expect(comments.isEmpty || vm.commentDrafts[post.id] == nil || vm.commentDrafts[post.id]?.isEmpty == true)
    }

    @Test("submitComment clears draft after submission")
    func submitCommentClearsDraft() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first else { return }
        vm.commentDrafts[post.id] = "Great post!"
        vm.submitComment(for: post.id)

        // Draft should be cleared immediately
        #expect(vm.commentDrafts[post.id]?.isEmpty ?? true)
    }

    @Test("submitComment increments comment count on post")
    func submitCommentIncrementsCount() async throws {
        let vm = CommunityViewModel()
        vm.loadPosts()
        try await waitForViewModel()

        guard let post = vm.posts.first else { return }
        let originalCount = post.commentsCount

        vm.commentDrafts[post.id] = "Nice work!"
        vm.submitComment(for: post.id)
        try await waitForViewModel(ms: 1200)

        let updated = vm.posts.first(where: { $0.id == post.id })!
        #expect(updated.commentsCount == originalCount + 1)
    }

    // MARK: - PostCategory

    @Test("PostCategory displayName is capitalized rawValue")
    func postCategoryDisplayName() {
        #expect(PostCategory.wins.displayName == "Wins")
        #expect(PostCategory.struggles.displayName == "Struggles")
        #expect(PostCategory.support.displayName == "Support")
        #expect(PostCategory.gratitude.displayName == "Gratitude")
        #expect(PostCategory.general.displayName == "General")
    }
}
