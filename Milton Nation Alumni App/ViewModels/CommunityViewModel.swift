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
    /// Surfaced to the user via .alert when a community action fails
    /// (e.g. delete-post network error).
    var errorMessage: String?

    // MARK: - Report / Block feedback (Apple Guideline 1.2)
    /// Drives a lightweight confirmation toast/alert after a report or block.
    var showActionConfirmation = false
    var actionConfirmationMessage = ""

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
    private var reconnectObserver: (any NSObjectProtocol)?

    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = DefaultServices.dataService) {
        self.dataService = dataService
        setupReconnectObserver()
    }

    deinit {
        if let observer = reconnectObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
            let safetyResult = await ContentFilterService.shared.analyzeAndEscalate(content, feature: .communityPost)
            let moderationResult = ModerationResult(
                status: safetyResult.riskLevel == .highRisk ? .crisis
                      : safetyResult.riskLevel == .safe     ? .clean : .flagged,
                matchedKeywords: safetyResult.matches.map(\.keyword)
            )
            let postStatus = ContentFilterService.shared.postStatus(
                for: moderationResult,
                approvedPostCount: approvedCount
            )

            do {
                _ = try await dataService.createPost(
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
            } catch {
                // Network/server failure — surface the real error, keep the draft
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.createPost")
                await MainActor.run {
                    postSubmissionMessage = "Couldn't post. Please check your connection and try again."
                    showPostSubmitted = true
                }
            }
        }
    }

    func toggleLike(post: CommunityPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        // Capture original state for rollback if the server call fails
        let wasLiked = posts[index].isLikedByCurrentUser
        let originalCount = posts[index].likesCount
        // Optimistic update
        posts[index].isLikedByCurrentUser.toggle()
        posts[index].likesCount += posts[index].isLikedByCurrentUser ? 1 : -1
        Task {
            do {
                _ = try await dataService.toggleLike(postId: post.id)
                if !wasLiked {
                    let _ = try? await dataService.awardPoints(action: .postLiked)
                }
            } catch {
                // Roll back optimistic update — server rejected the change
                await MainActor.run {
                    if let i = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[i].isLikedByCurrentUser = wasLiked
                        posts[i].likesCount = originalCount
                    }
                }
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.toggleLike")
            }
        }
    }

    // MARK: - Comments

    /// Optimistically toggle a comment's like state in `commentsByPost`, then
    /// reconcile against the server via `toggleCommentLike` RPC. Rolls back if
    /// the server call fails (e.g. network).
    func toggleCommentLike(postId: UUID, commentId: UUID) {
        guard
            var list = commentsByPost[postId],
            let idx = list.firstIndex(where: { $0.id == commentId })
        else { return }

        let wasLiked = list[idx].isLikedByCurrentUser
        let originalCount = list[idx].likesCount
        list[idx].isLikedByCurrentUser.toggle()
        list[idx].likesCount = max(0, originalCount + (list[idx].isLikedByCurrentUser ? 1 : -1))
        commentsByPost[postId] = list

        Task {
            do {
                _ = try await dataService.toggleCommentLike(commentId: commentId)
            } catch {
                // Roll back optimistic update if the server rejected the change
                await MainActor.run {
                    if var rb = commentsByPost[postId],
                       let i = rb.firstIndex(where: { $0.id == commentId }) {
                        rb[i].isLikedByCurrentUser = wasLiked
                        rb[i].likesCount = originalCount
                        commentsByPost[postId] = rb
                    }
                }
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.toggleCommentLike")
            }
        }
    }

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
            // Run comment through full moderation pipeline (local + server escalation)
            let safetyResult = await ContentFilterService.shared.analyzeAndEscalate(
                draft,
                userId: currentUser?.id,
                feature: .communityPost
            )
            let commentStatus: PostStatus
            switch safetyResult.riskLevel {
            case .highRisk: commentStatus = .flaggedForCrisis
            case .mediumRisk, .lowRisk: commentStatus = .pendingReview
            case .safe:     commentStatus = .approved
            }

            do {
                let comment = try await dataService.addComment(
                    postId: postId,
                    content: draft,
                    status: commentStatus,
                    matchedKeywords: safetyResult.matches.map(\.keyword)
                )
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
            } catch {
                // Restore the draft so the user can retry
                await MainActor.run {
                    commentDrafts[postId] = draft
                    postSubmissionMessage = "Failed to post comment. Please try again."
                    showPostSubmitted = true
                }
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.submitComment")
            }
        }
    }

    /// Preload the latest comment for each post (for preview under posts).
    /// Limited to the first 10 posts to avoid flooding the network with concurrent requests.
    func preloadLatestComments() {
        let postsToPreload = posts.prefix(10).filter { commentsByPost[$0.id] == nil }
        for post in postsToPreload {
            let postId = post.id
            Task {
                let fetched = (try? await dataService.fetchComments(postId: postId)) ?? []
                await MainActor.run {
                    commentsByPost[postId] = fetched
                }
            }
        }
    }

    // MARK: - Realtime Subscriptions

    /// Re-subscribes to post updates when the app returns to foreground.
    private func setupReconnectObserver() {
        reconnectObserver = NotificationCenter.default.addObserver(
            forName: RealtimeService.reconnectNeeded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isSubscribedToRealtime = false
            self.subscribeToPostUpdates()
        }
    }

    /// Subscribe to live post updates (new approved posts, status changes).
    private func subscribeToPostUpdates() {
        guard SupabaseConfig.isConfigured else { return }
        // Skip Realtime in unit test runs — the shared channel singleton causes fatal errors
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
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

    // MARK: - Delete post (own)

    /// Remove a post the current user owns. Removes optimistically from the
    /// local list, then sends the DELETE to the backend. On failure, restores.
    func deletePost(_ post: CommunityPost, completion: (() -> Void)? = nil) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
            completion?()
            return
        }
        let removed = posts[index]
        posts.remove(at: index)
        Task {
            do {
                try await dataService.deletePost(postId: post.id)
                await MainActor.run { completion?() }
            } catch {
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.deletePost")
                await MainActor.run {
                    // Reinsert at the original index on failure
                    self.posts.insert(removed, at: min(index, self.posts.count))
                    self.errorMessage = "Couldn't delete that post. Please try again."
                    completion?()
                }
            }
        }
    }

    /// Edit a post the current user owns. Pushes content (and optionally
    /// media) back through admin review by setting status to pendingReview.
    /// Updates the local list immediately so the UI reflects the edit.
    func updatePost(
        postId: UUID,
        newContent: String,
        newMediaURL: String? = nil,
        newMediaType: CommunityPost.MediaType? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        Task {
            // CRITICAL: edits MUST run through the same moderation pipeline
            // that createPost/submitComment use. Without this, a user could
            // post clean content, get it approved, then edit it to contain
            // crisis phrases — and the edit would only sit in pending_review
            // instead of flaggedForCrisis. That's a safety-critical hole on
            // a recovery app. We match the exact pattern from createPost():
            // analyze locally + server-escalate, then map risk → status.
            let safetyResult = await ContentFilterService.shared.analyzeAndEscalate(
                newContent,
                userId: currentUser?.id,
                feature: .communityPost
            )
            let mappedStatus: PostStatus
            switch safetyResult.riskLevel {
            case .highRisk:                  mappedStatus = .flaggedForCrisis
            case .mediumRisk, .lowRisk:      mappedStatus = .pendingReview
            case .safe:                      mappedStatus = .pendingReview
                // ^ Even "safe" content goes back to pending_review after an
                //   edit — an admin re-approves before community sees it.
            }

            do {
                var updated = try await dataService.updatePostContent(
                    postId: postId,
                    newContent: newContent,
                    newMediaURL: newMediaURL,
                    newMediaType: newMediaType
                )
                // SupabaseDataService.updatePostContent sets status to
                // pendingReview unconditionally. If our local moderation
                // returned highRisk, escalate the in-memory copy now and
                // moderate-out: the server-side flag-content function (called
                // by analyzeAndEscalate above) already pushed the alert to
                // admins, so the post object just needs to reflect that.
                if mappedStatus == .flaggedForCrisis {
                    updated.status = .flaggedForCrisis
                    updated.matchedKeywords = safetyResult.matches.map(\.keyword)
                }
                await MainActor.run {
                    if let i = posts.firstIndex(where: { $0.id == postId }) {
                        posts[i] = updated
                    }
                    postSubmissionMessage = updated.status == .flaggedForCrisis
                        ? "Edit submitted. Our team will reach out shortly."
                        : "Edit submitted for review"
                    showPostSubmitted = true
                    completion?(true)
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.updatePost")
                await MainActor.run {
                    errorMessage = "Couldn't update that post. Please try again."
                    completion?(false)
                }
            }
        }
    }

    // MARK: - Report & Block (Apple Guideline 1.2)

    /// Report a post to the admin moderation queue. Fire-and-confirm: shows a
    /// success toast, or an error message if the network call fails.
    func reportPost(_ post: CommunityPost, reason: String? = nil) {
        Task {
            do {
                try await dataService.reportPost(post.id, reason: reason)
                await MainActor.run {
                    actionConfirmationMessage = "Thanks for reporting. Our team will review this post."
                    showActionConfirmation = true
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.reportPost")
                await MainActor.run {
                    errorMessage = "Couldn't submit that report. Please try again."
                }
            }
        }
    }

    /// Report a comment to the admin moderation queue.
    func reportComment(postId: UUID, commentId: UUID, reason: String? = nil) {
        Task {
            do {
                try await dataService.reportComment(commentId, reason: reason)
                await MainActor.run {
                    actionConfirmationMessage = "Thanks for reporting. Our team will review this comment."
                    showActionConfirmation = true
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.reportComment")
                await MainActor.run {
                    errorMessage = "Couldn't submit that report. Please try again."
                }
            }
        }
    }

    /// Block a user. Optimistically removes their posts (and any loaded
    /// comments) from the current feed, then persists the block. On failure,
    /// reloads the feed so nothing is left in a half-blocked state.
    func blockUser(_ userId: UUID, displayName: String) {
        // Optimistically purge their content from what's on screen now.
        posts.removeAll { $0.userId == userId }
        for (postId, list) in commentsByPost {
            commentsByPost[postId] = list.filter { $0.userId != userId }
        }
        Task {
            do {
                try await dataService.blockUser(userId)
                await MainActor.run {
                    actionConfirmationMessage = "\(displayName) has been blocked. You won't see their posts or comments."
                    showActionConfirmation = true
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "CommunityViewModel.blockUser")
                await MainActor.run {
                    errorMessage = "Couldn't block that user. Please try again."
                    // Reload so the optimistic removal doesn't desync from server.
                    loadPosts()
                }
            }
        }
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
