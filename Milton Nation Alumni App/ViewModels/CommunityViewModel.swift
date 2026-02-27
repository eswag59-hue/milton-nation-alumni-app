import SwiftUI
import UserNotifications

@Observable
final class CommunityViewModel {
    var posts: [CommunityPost] = []
    var selectedCategory: PostCategory? = nil
    var showCreatePost = false
    var newPostContent = ""
    var newPostCategory: PostCategory = .general
    var isLoading = false
    var showPostSubmitted = false
    var postSubmissionMessage = ""
    var searchText = ""

    /// Reference to the current user for auto-approve threshold checks.
    var currentUser: User?

    /// Filtered posts based on search text.
    var filteredPosts: [CommunityPost] {
        if searchText.isEmpty { return posts }
        return posts.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.userName.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Media attachment state
    var selectedMediaData: Data?
    var selectedMediaType: CommunityPost.MediaType?
    var showMediaPicker = false

    // MARK: - Comment State

    /// Comments keyed by post ID.
    var commentsByPost: [UUID: [Comment]] = [:]
    /// Tracks which posts have their comment section expanded.
    var expandedCommentPostIds: Set<UUID> = []
    /// Draft text for new comments, keyed by post ID.
    var commentDrafts: [UUID: String] = [:]
    /// Posts whose comments are currently being fetched.
    var loadingCommentPostIds: Set<UUID> = []

    /// Whether Realtime is currently subscribed.
    private var isSubscribedToRealtime = false

    // MARK: - Task Cancellation
    private var loadPostsTask: Task<Void, Never>?

    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = MockDataService()) {
        self.dataService = dataService
    }

    // MARK: - Posts

    func loadPosts() {
        loadPostsTask?.cancel()
        loadPostsTask = Task {
            await MainActor.run { isLoading = true }
            let fetched = (try? await dataService.fetchPosts(category: selectedCategory)) ?? []
            guard !Task.isCancelled else { return }
            await MainActor.run {
                posts = fetched
                isLoading = false
            }

            // Start Realtime subscription on first load
            if !isSubscribedToRealtime {
                subscribeToPostUpdates()
            }
        }
    }

    func filterByCategory(_ category: PostCategory?) {
        selectedCategory = category
        loadPosts()
    }

    func createPost() {
        guard !newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let content = newPostContent
        let category = newPostCategory
        let mediaData = selectedMediaData
        let mediaType = selectedMediaType
        let approvedCount = currentUser?.approvedPostCount ?? 0

        Task {
            // Run content through moderation pipeline
            let moderationResult = await ContentFilterService.shared.moderateText(content)
            let postStatus = ContentFilterService.shared.postStatus(
                for: moderationResult,
                approvedPostCount: approvedCount
            )

            let _ = try? await dataService.createPost(
                content: content,
                category: category,
                mediaData: mediaData,
                mediaType: mediaType,
                status: postStatus,
                matchedKeywords: moderationResult.matchedKeywords
            )
            let _ = try? await dataService.awardPoints(action: .postCreated)
            await MainActor.run {
                newPostContent = ""
                newPostCategory = .general
                selectedMediaData = nil
                selectedMediaType = nil
                showCreatePost = false

                // Set appropriate user feedback
                switch postStatus {
                case .approved:
                    postSubmissionMessage = "Post published!"
                case .pending:
                    postSubmissionMessage = "Post submitted for review."
                case .pendingReview:
                    postSubmissionMessage = "Post submitted for review."
                case .flaggedForCrisis:
                    postSubmissionMessage = "Your post has been submitted. A care team member will reach out to you."
                case .rejected:
                    postSubmissionMessage = "Post submitted."
                }
                showPostSubmitted = true

                // If auto-approved, increment the approved count
                if postStatus == .approved {
                    currentUser?.approvedPostCount += 1
                }
            }
        }
    }

    func toggleLike(post: CommunityPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLikedByCurrentUser.toggle()
        posts[index].likesCount += posts[index].isLikedByCurrentUser ? 1 : -1
        Task {
            let _ = try? await dataService.toggleLike(postId: post.id)
            if posts[index].isLikedByCurrentUser {
                let _ = try? await dataService.awardPoints(action: .postLiked)
            }
        }
    }

    // MARK: - Comments

    /// Toggles the comment section for a given post. Fetches comments on first expand.
    func toggleComments(for postId: UUID) {
        if expandedCommentPostIds.contains(postId) {
            expandedCommentPostIds.remove(postId)
        } else {
            expandedCommentPostIds.insert(postId)
            if commentsByPost[postId] == nil {
                loadComments(for: postId)
            }
        }
    }

    func loadComments(for postId: UUID) {
        loadingCommentPostIds.insert(postId)
        Task {
            let fetched = (try? await dataService.fetchComments(postId: postId)) ?? []
            await MainActor.run {
                commentsByPost[postId] = fetched
                loadingCommentPostIds.remove(postId)
            }
        }
    }

    func submitComment(for postId: UUID) {
        let draft = (commentDrafts[postId] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !draft.isEmpty else { return }
        commentDrafts[postId] = ""

        Task {
            // Run comment through local content filter
            let filterResult = ContentFilterService.shared.localFilter(draft)
            let commentStatus: PostStatus
            switch filterResult.status {
            case .crisis:  commentStatus = .flaggedForCrisis
            case .flagged: commentStatus = .pendingReview
            case .clean:   commentStatus = .approved
            }

            if let comment = try? await dataService.addComment(
                postId: postId,
                content: draft,
                status: commentStatus,
                matchedKeywords: filterResult.matchedKeywords
            ) {
                let _ = try? await dataService.awardPoints(action: .postCreated)
                await MainActor.run {
                    commentsByPost[postId, default: []].append(comment)
                    // Update the comment count on the post itself
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index].commentsCount += 1

                        // Trigger push notification to post author
                        let postAuthor = posts[index].userName
                        sendCommentNotification(
                            commenterName: comment.userName,
                            postAuthorName: postAuthor
                        )
                    }

                    // Show feedback for crisis content
                    if commentStatus == .flaggedForCrisis {
                        postSubmissionMessage = "Your comment has been flagged. A care team member will reach out to you."
                        showPostSubmitted = true
                    }
                }
            }
        }
    }

    /// Preload the latest comment for each post (for preview under posts).
    func preloadLatestComments() {
        for post in posts {
            if commentsByPost[post.id] == nil {
                Task {
                    let fetched = (try? await dataService.fetchComments(postId: post.id)) ?? []
                    await MainActor.run {
                        commentsByPost[post.id] = fetched
                    }
                }
            }
        }
    }

    // MARK: - Realtime Subscriptions

    /// Subscribe to live post updates (new approved posts, status changes).
    private func subscribeToPostUpdates() {
        guard SupabaseConfig.isConfigured else { return }
        isSubscribedToRealtime = true

        RealtimeService.shared.subscribeToPosts(
            onInsert: { [weak self] post in
                guard let self else { return }
                // Only add if matching current category filter and not already present
                if let category = self.selectedCategory, post.category != category { return }
                if !self.posts.contains(where: { $0.id == post.id }) {
                    self.posts.insert(post, at: 0)
                }
            },
            onUpdate: { [weak self] updatedPost in
                guard let self else { return }
                if let index = self.posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    // Preserve client-side state (isLikedByCurrentUser)
                    var merged = updatedPost
                    merged.isLikedByCurrentUser = self.posts[index].isLikedByCurrentUser
                    self.posts[index] = merged
                } else if updatedPost.status == .approved {
                    // Post was just approved — add to feed
                    if let category = self.selectedCategory, updatedPost.category != category { return }
                    self.posts.insert(updatedPost, at: 0)
                }
            }
        )
    }

    /// Unsubscribe from Realtime when leaving the community view.
    func stopRealtimeUpdates() {
        RealtimeService.shared.unsubscribeFromPosts()
        isSubscribedToRealtime = false
    }

    // MARK: - Cleanup

    func cancelTasks() {
        loadPostsTask?.cancel()
        loadPostsTask = nil
    }

    // MARK: - Push Notification

    private func sendCommentNotification(commenterName: String, postAuthorName: String) {
        // Use PushNotificationService for local notification
        // (In production with Edge Functions, this would be a server-side push)
        PushNotificationService.shared.scheduleLocalNotification(
            title: "New Comment",
            body: "\(commenterName) commented on your post"
        )
    }
}
