import SwiftUI

struct CommunityScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = CommunityViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with logo
                ZStack {
                    MiltonLogoView(size: .small)
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showCreatePost = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Post")
                            }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundStyle(.white)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)

                // Category filter
                CategoryFilterBar(selectedCategory: $viewModel.selectedCategory)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackground)
                    .onChange(of: viewModel.selectedCategory) {
                        viewModel.loadPosts()
                    }

                Divider()

                // Posts
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                        Text("No posts yet")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Be the first to share in this category")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Button {
                            viewModel.showCreatePost = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Create Post")
                            }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts) { post in
                                PostCard(
                                    post: post,
                                    onLike: { viewModel.toggleLike(post: post) },
                                    onToggleComments: { viewModel.toggleComments(for: post.id) },
                                    onSubmitComment: { viewModel.submitComment(for: post.id) },
                                    comments: viewModel.commentsByPost[post.id] ?? [],
                                    isLoadingComments: viewModel.loadingCommentPostIds.contains(post.id),
                                    isCommentsExpanded: viewModel.expandedCommentPostIds.contains(post.id),
                                    commentDraft: Binding(
                                        get: { viewModel.commentDrafts[post.id] ?? "" },
                                        set: { viewModel.commentDrafts[post.id] = $0 }
                                    )
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppTheme.background)
            .sheet(isPresented: $viewModel.showCreatePost) {
                CreatePostSheet(viewModel: viewModel)
            }
            .alert("Post Submitted", isPresented: $viewModel.showPostSubmitted) {
                Button("OK") {}
            } message: {
                Text("Your post has been submitted for review and will appear once approved.")
            }
            .onAppear {
                viewModel.loadPosts()
                // Preload latest comments for preview under each post
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.preloadLatestComments()
                }
            }
        }
    }
}
