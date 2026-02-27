import SwiftUI

struct PostCard: View {
    let post: CommunityPost
    var onLike: () -> Void = {}
    var onToggleComments: () -> Void = {}
    var onSubmitComment: () -> Void = {}

    /// Comments to display beneath the post.
    var comments: [Comment] = []
    /// Whether comments are currently loading.
    var isLoadingComments: Bool = false
    /// Whether the comment section is expanded.
    var isCommentsExpanded: Bool = false
    /// Binding to the draft comment text for this post.
    @Binding var commentDraft: String

    // Convenience init for previews / callers that don't need comments yet
    init(
        post: CommunityPost,
        onLike: @escaping () -> Void = {},
        onToggleComments: @escaping () -> Void = {},
        onSubmitComment: @escaping () -> Void = {},
        comments: [Comment] = [],
        isLoadingComments: Bool = false,
        isCommentsExpanded: Bool = false,
        commentDraft: Binding<String> = .constant("")
    ) {
        self.post = post
        self.onLike = onLike
        self.onToggleComments = onToggleComments
        self.onSubmitComment = onSubmitComment
        self.comments = comments
        self.isLoadingComments = isLoadingComments
        self.isCommentsExpanded = isCommentsExpanded
        self._commentDraft = commentDraft
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
            }

            // Content
            Text(post.content)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(5)

            // Media preview
            if post.mediaURL != nil {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.background)
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: post.mediaType == .video ? "play.circle.fill" : "photo.fill")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                            Text(post.mediaType == .video ? "Video" : "Photo")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
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
            if !isCommentsExpanded, let latestComment = comments.last ?? (post.commentsCount > 0 ? nil : nil) {
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
