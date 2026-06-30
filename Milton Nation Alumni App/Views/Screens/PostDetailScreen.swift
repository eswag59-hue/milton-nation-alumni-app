import SwiftUI

/// Full-screen detail view for a single community post — shows the post,
/// every comment, the like state, and lets the user comment. If the user
/// owns the post, a trash-can icon in the toolbar deletes it. Opened from
/// CommunityScreen and ProfileScreen "My Posts" via NavigationLink.
struct PostDetailScreen: View {
    let postId: UUID

    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    @Bindable var communityVM: CommunityViewModel
    @State private var showDeleteConfirm = false
    @State private var commentDraft = ""
    @State private var isLoading = false
    @FocusState private var commentFocused: Bool

    // Edit-post state — opens a small sheet pre-filled with the post's
    // current content. Submitting calls updatePost on the VM which sets
    // the post back to pendingReview so an admin re-approves the edit.
    @State private var showEditSheet = false
    @State private var editDraft = ""

    // Report / Block confirmation targets for comments (Apple Guideline 1.2)
    @State private var commentToReport: Comment?
    @State private var commentAuthorToBlock: Comment?

    // Pull the post live from the VM so it updates as likes/comments come in
    private var post: CommunityPost? {
        communityVM.posts.first(where: { $0.id == postId })
    }
    private var comments: [Comment] {
        communityVM.commentsByPost[postId] ?? []
    }
    private var isOwnPost: Bool {
        guard let post, let me = appViewModel.currentUser else { return false }
        return post.userId == me.id
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let post {
                    VStack(spacing: 16) {
                        // The post itself
                        PostCard(
                            post: post,
                            onLike: { communityVM.toggleLike(post: post) },
                            onToggleComments: {},
                            onSubmitComment: {},
                            onReportPost: { communityVM.reportPost(post) },
                            onBlockPost: {
                                communityVM.blockUser(post.userId, displayName: post.userName)
                                // The post is gone from the feed now — leave detail.
                                dismiss()
                            },
                            currentUserId: appViewModel.currentUser?.id,
                            comments: [],
                            isLoadingComments: false,
                            isCommentsExpanded: false,
                            commentDraft: .constant("")
                        )
                        .padding(.horizontal)

                        // All comments, large + scrollable
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundStyle(AppTheme.accent)
                                Text("Comments")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("\(comments.count)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            if isLoading && comments.isEmpty {
                                HStack { Spacer(); ProgressView().controlSize(.small); Spacer() }
                                    .padding(.vertical, 24)
                            } else if comments.isEmpty {
                                Text("No comments yet. Be the first!")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(comments) { comment in
                                    commentRow(comment)
                                    Divider().padding(.leading, 40)
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                        .padding(.horizontal)

                        Color.clear.frame(height: 120) // breathing room for the comment input
                    }
                    .padding(.top, 12)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                        Text("This post is no longer available.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Sticky comment input at the bottom
            if post != nil {
                Divider()
                HStack(spacing: 8) {
                    TextField("Add a comment...", text: $commentDraft)
                        .focused($commentFocused)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button {
                        submitComment()
                    } label: {
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
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(AppTheme.cardBackground)
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwnPost {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            // Pre-fill the editor with the current content
                            editDraft = post?.content ?? ""
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Post options")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            // Lightweight editor sheet. We can't reuse CreatePostSheet here
            // because it constructs a brand-new post — we want to mutate the
            // existing post and push it back to pending_review.
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Edits go back through review")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextEditor(text: $editDraft)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(minHeight: 200)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .navigationTitle("Edit Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showEditSheet = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            let trimmed = editDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            communityVM.updatePost(postId: postId, newContent: trimmed) { _ in }
                            showEditSheet = false
                        }
                        .disabled(editDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .bold()
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Delete this post?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let post {
                    communityVM.deletePost(post) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently remove your post and all its comments. This can't be undone.")
        }
        // MARK: - Comment Report / Block confirmations (Apple Guideline 1.2)
        .confirmationDialog(
            "Report this comment?",
            isPresented: Binding(
                get: { commentToReport != nil },
                set: { if !$0 { commentToReport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Report", role: .destructive) {
                if let c = commentToReport {
                    communityVM.reportComment(postId: postId, commentId: c.id)
                }
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
                if let c = commentAuthorToBlock {
                    communityVM.blockUser(c.userId, displayName: c.userName)
                }
                commentAuthorToBlock = nil
            }
            Button("Cancel", role: .cancel) { commentAuthorToBlock = nil }
        } message: {
            Text("You won't see posts or comments from this person. You can unblock them anytime in Settings.")
        }
        // Report / Block success + failure surfaces
        .alert("Done", isPresented: $communityVM.showActionConfirmation) {
            Button("OK") {}
        } message: {
            Text(communityVM.actionConfirmationMessage)
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { communityVM.errorMessage != nil },
                set: { if !$0 { communityVM.errorMessage = nil } }
            )
        ) {
            Button("OK") { communityVM.errorMessage = nil }
        } message: {
            Text(communityVM.errorMessage ?? "")
        }
        .onAppear {
            loadComments()
        }
    }

    private func loadComments() {
        isLoading = true
        communityVM.loadComments(for: postId)
        // CommunityViewModel.loadComments fires-and-forgets via Task internally;
        // we just guard the spinner from flashing forever.
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            await MainActor.run { isLoading = false }
        }
    }

    private func submitComment() {
        let trimmed = commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // The VM keeps drafts keyed by post id — set the draft, then call submit
        communityVM.commentDrafts[postId] = trimmed
        commentDraft = ""
        commentFocused = false
        communityVM.submitComment(for: postId)
    }

    @ViewBuilder
    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppTheme.accent.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(comment.userName.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.accent)
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.userName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)

            // Report / Block menu for OTHER people's comments only.
            if let me = appViewModel.currentUser?.id, comment.userId != me {
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
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Comment options")
            }

            // Heart button on each comment — filled red when liked.
            // Tap routes to CommunityViewModel.toggleCommentLike, which does
            // an optimistic mutate + RPC reconciliation.
            Button {
                communityVM.toggleCommentLike(postId: postId, commentId: comment.id)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.subheadline)
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
        .padding(.vertical, 6)
    }
}
