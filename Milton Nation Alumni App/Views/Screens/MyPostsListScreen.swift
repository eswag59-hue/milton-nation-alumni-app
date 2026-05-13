import SwiftUI

/// Dedicated list of posts authored by the current user, reachable from the
/// "My Posts" row on the Profile screen. Each row is a thin PostCard inside
/// a NavigationLink to PostDetailScreen — tapping a post takes the user to
/// the full detail screen where Edit/Delete live in the toolbar menu.
struct MyPostsListScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Bindable var communityVM: CommunityViewModel
    @State private var hasLoaded = false

    private var myPosts: [CommunityPost] {
        guard let me = appViewModel.currentUser else { return [] }
        return communityVM.posts.filter { $0.userId == me.id }
    }

    var body: some View {
        ScrollView {
            if myPosts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.text.square")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                    Text("No posts yet")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Posts you share in the community will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(myPosts) { post in
                        NavigationLink(value: post.id) {
                            PostCard(
                                post: post,
                                comments: [],
                                isLoadingComments: false,
                                isCommentsExpanded: false,
                                commentDraft: .constant("")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.background)
        .navigationTitle("My Posts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UUID.self) { postId in
            PostDetailScreen(postId: postId, communityVM: communityVM)
        }
        .onAppear {
            // CommunityVM is fresh when entering from Profile — load the feed
            // once so the filter has data. Subsequent navigations reuse it.
            if !hasLoaded {
                communityVM.currentUser = appViewModel.currentUser
                communityVM.loadPosts()
                hasLoaded = true
            }
        }
    }
}
