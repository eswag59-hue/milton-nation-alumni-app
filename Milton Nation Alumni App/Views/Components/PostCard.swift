import SwiftUI

struct PostCard: View {
    let post: CommunityPost
    var onLike: () -> Void = {}
    var onToggleComments: () -> Void = {}
    var onSubmitComment: () -> Void = {}
    /// Called when the user taps the heart on a specific comment.
    /// The comment's UUID is passed so callers can route to the right row.
    var onLikeComment: (UUID) -> Void = { _ in }

    // MARK: - Report / Block callbacks (Apple Guideline 1.2)
    /// Report this post. Hidden when the post is the current user's own.
    var onReportPost: () -> Void = {}
    /// Block the post's author. Hidden when the post is the current user's own.
    var onBlockPost: () -> Void = {}
    /// Report a specific comment (passed its UUID).
    var onReportComment: (UUID) -> Void = { _ in }
    /// Block a specific comment's author (passed the comment's author UUID).
    var onBlockComment: (_ authorId: UUID, _ authorName: String) -> Void = { _, _ in }
    /// The current user's id, used to hide Report/Block on the user's OWN
    /// content. `nil` (e.g. previews) hides the controls entirely.
    var currentUserId: UUID? = nil

    /// Comments to display beneath the post.
    var comments: [Comment] = []
    /// Whether comments are currently loading.
    var isLoadingComments: Bool = false
    /// Whether the comment section is expanded.
    var isCommentsExpanded: Bool = false
    /// Binding to the draft comment text for this post.
    @Binding var commentDraft: String

    // MARK: - Report / Block confirmation state
    @State private var showReportPostConfirm = false
    @State private var showBlockUserConfirm = false
    /// Tapping the post image opens it fullscreen. In the feed the card is
    /// wrapped in a NavigationLink so this tap is consumed by navigation (image
    /// → post detail); in the post detail there's no link, so it opens fullscreen.
    @State private var fullScreenImageURL: IdentifiableURL?
    /// The comment currently targeted by a report/block confirmation, if any.
    @State private var commentToReport: Comment?
    @State private var commentAuthorToBlock: Comment?

    // Convenience init for previews / callers that don't need comments yet
    init(
        post: CommunityPost,
        onLike: @escaping () -> Void = {},
        onToggleComments: @escaping () -> Void = {},
        onSubmitComment: @escaping () -> Void = {},
        onLikeComment: @escaping (UUID) -> Void = { _ in },
        onReportPost: @escaping () -> Void = {},
        onBlockPost: @escaping () -> Void = {},
        onReportComment: @escaping (UUID) -> Void = { _ in },
        onBlockComment: @escaping (_ authorId: UUID, _ authorName: String) -> Void = { _, _ in },
        currentUserId: UUID? = nil,
        comments: [Comment] = [],
        isLoadingComments: Bool = false,
        isCommentsExpanded: Bool = false,
        commentDraft: Binding<String> = .constant("")
    ) {
        self.post = post
        self.onLike = onLike
        self.onToggleComments = onToggleComments
        self.onSubmitComment = onSubmitComment
        self.onLikeComment = onLikeComment
        self.onReportPost = onReportPost
        self.onBlockPost = onBlockPost
        self.onReportComment = onReportComment
        self.onBlockComment = onBlockComment
        self.currentUserId = currentUserId
        self.comments = comments
        self.isLoadingComments = isLoadingComments
        self.isCommentsExpanded = isCommentsExpanded
        self._commentDraft = commentDraft
    }

    /// True when the post belongs to someone other than the current user — the
    /// only case where Report / Block should appear (never on your own content).
    private var canModeratePost: Bool {
        guard let me = currentUserId else { return false }
        return post.userId != me
    }

    /// One post image. `width == nil` → full-width single image; a value → fixed
    /// width for the horizontal multi-photo gallery. Tapping opens fullscreen.
    @ViewBuilder
    private func postImage(_ url: URL, width: CGFloat?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: width == nil ? .infinity : nil)
                    .frame(width: width, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture { fullScreenImageURL = IdentifiableURL(url: url) }
            case .failure:
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.background)
                    .frame(maxWidth: width == nil ? .infinity : nil)
                    .frame(width: width, height: 200)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("Image unavailable")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
            case .empty:
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.background.opacity(0.5))
                    .frame(maxWidth: width == nil ? .infinity : nil)
                    .frame(width: width, height: 200)
                    .overlay { ProgressView() }
            @unknown default:
                EmptyView()
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pinned indicator
            if post.isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                    Text("Pinned")
                }
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.accent)
            }

            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(AppTheme.accent.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(post.userName.prefix(1)))
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(post.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                categoryBadge

                // Report / Block menu — only on OTHER people's posts.
                if canModeratePost {
                    Menu {
                        Button(role: .destructive) {
                            showReportPostConfirm = true
                        } label: {
                            Label("Report Post", systemImage: "flag")
                        }
                        Button(role: .destructive) {
                            showBlockUserConfirm = true
                        } label: {
                            Label("Block \(post.userName)", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.leading, 6)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Post options")
                    // Stop the menu tap from triggering the surrounding
                    // NavigationLink (PostCard is wrapped in one in the feed).
                    .buttonStyle(.plain)
                }
            }

            // Content
            Text(post.content)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(5)

            // Media preview
            if post.mediaType == .video, post.mediaURL != nil {
                // Video — show thumbnail placeholder with play icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                            Text("Video")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
            } else {
                let imageURLs = post.allImageURLs.compactMap { URL(string: $0) }
                if imageURLs.count == 1 {
                    postImage(imageURLs[0], width: nil)   // full width single image
                } else if imageURLs.count > 1 {
                    // Multi-photo — horizontal gallery with a counter.
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(imageURLs.enumerated()), id: \.offset) { _, url in
                                postImage(url, width: 260)
                            }
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        Text("1–\(imageURLs.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(.black.opacity(0.55)))
                            .padding(8)
                    }
                }
            }

            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLikedByCurrentUser ? AppTheme.struggling : AppTheme.textSecondary)
                        Text("\(post.likesCount)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .accessibilityLabel(post.isLikedByCurrentUser ? "Unlike post, \(post.likesCount) likes" : "Like post, \(post.likesCount) likes")

                Button(action: onToggleComments) {
                    HStack(spacing: 4) {
                        Image(systemName: isCommentsExpanded ? "bubble.right.fill" : "bubble.right")
                            .foregroundStyle(isCommentsExpanded ? AppTheme.accent : AppTheme.textSecondary)
                        Text("\(post.commentsCount)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .accessibilityLabel("\(post.commentsCount) comments, double tap to \(isCommentsExpanded ? "collapse" : "expand")")

                Spacer()
            }

            // Most recent comment preview (when comments not expanded)
            if !isCommentsExpanded, let latestComment = comments.last {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    Text("\(Text(latestComment.userName).font(.caption2.bold()).foregroundStyle(AppTheme.textPrimary))  \(Text(latestComment.content).font(.caption2).foregroundStyle(AppTheme.textSecondary))")
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }

            // MARK: - Inline Comments Section
            if isCommentsExpanded {
                Divider()

                if isLoadingComments {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else if comments.isEmpty {
                    Text("No comments yet. Be the first!")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(comments) { comment in
                            commentRow(comment)
                        }
                    }
                }

                // Comment input
                HStack(spacing: 8) {
                    TextField("Add a comment...", text: $commentDraft)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button(action: onSubmitComment) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? AppTheme.textSecondary.opacity(0.4)
                                    : AppTheme.accent
                            )
                    }
                    .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding()
        .cardStyle()
        .fullScreenCover(item: $fullScreenImageURL) { item in
            FullScreenImageView(url: item.url)
        }
        // MARK: - Report / Block confirmations
        .confirmationDialog(
            "Report this post?",
            isPresented: $showReportPostConfirm,
            titleVisibility: .visible
        ) {
            Button("Report", role: .destructive) { onReportPost() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Our team will review this post. Reporting is anonymous.")
        }
        .confirmationDialog(
            "Block \(post.userName)?",
            isPresented: $showBlockUserConfirm,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) { onBlockPost() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't see posts or comments from \(post.userName). You can unblock them anytime in Settings.")
        }
        .confirmationDialog(
            "Report this comment?",
            isPresented: Binding(
                get: { commentToReport != nil },
                set: { if !$0 { commentToReport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Report", role: .destructive) {
                if let c = commentToReport { onReportComment(c.id) }
                commentToReport = nil
            }
            Button("Cancel", role: .cancel) { commentToReport = nil }
        } message: {
            Text("Our team will review this comment. Reporting is anonymous.")
        }
        .confirmationDialog(
            commentAuthorToBlock.map { "Block \($0.userName)?" } ?? "Block user?",
            isPresented: Binding(
                get: { commentAuthorToBlock != nil },
                set: { if !$0 { commentAuthorToBlock = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                if let c = commentAuthorToBlock { onBlockComment(c.userId, c.userName) }
                commentAuthorToBlock = nil
            }
            Button("Cancel", role: .cancel) { commentAuthorToBlock = nil }
        } message: {
            Text("You won't see posts or comments from this person. You can unblock them anytime in Settings.")
        }
    }

    // MARK: - Subviews

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(AppTheme.accent.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(String(comment.userName.prefix(1)))
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(comment.userName)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer(minLength: 0)

            // Report / Block menu for OTHER people's comments only.
            if let me = currentUserId, comment.userId != me {
                Menu {
                    Button(role: .destructive) {
                        commentToReport = comment
                    } label: {
                        Label("Report Comment", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        commentAuthorToBlock = comment
                    } label: {
                        Label("Block \(comment.userName)", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Comment options")
                .buttonStyle(.plain)
            }

            // Heart button — filled red when the user has liked this comment.
            // Lives inline so the tap target is large enough but doesn't shift
            // the comment text. Count is hidden when 0 to keep the row clean.
            Button {
                onLikeComment(comment.id)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(comment.isLikedByCurrentUser ? .red : AppTheme.textSecondary)
                    if comment.likesCount > 0 {
                        Text("\(comment.likesCount)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryBadge: some View {
        let color: Color = {
            switch post.category {
            case .wins: return AppTheme.winsColor
            case .struggles: return AppTheme.strugglesColor
            case .support: return AppTheme.supportColor
            case .gratitude: return AppTheme.gratitudeColor
            case .general: return AppTheme.generalColor
            }
        }()
        return Text("\(post.category.emoji) \(post.category.displayName)")
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
