import SwiftUI

/// Settings → Blocked Users. Lists everyone the current user has blocked
/// (Apple Guideline 1.2) and lets them unblock with one tap. Blocked users'
/// posts, comments, and messages are filtered out of every feed until unblocked.
struct BlockedUsersScreen: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var blocked: [BlockedUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    /// IDs currently mid-unblock, so the row's button can show progress + disable.
    @State private var unblocking: Set<UUID> = []

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if blocked.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                    Text("No blocked users")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("People you block won't be able to appear in your community feed or messages. You can block someone from the menu on their post or comment.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(blocked) { user in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text(String(user.displayName.prefix(1)).uppercased())
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppTheme.accent)
                                }
                            Text(user.displayName)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            if unblocking.contains(user.id) {
                                ProgressView().controlSize(.small)
                            } else {
                                Button("Unblock") {
                                    unblock(user)
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } footer: {
                    Text("Unblocking someone restores their posts, comments, and messages in your feeds.")
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.accent)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            let result = try await appViewModel.dataService.fetchBlockedUsers()
            await MainActor.run {
                blocked = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't load your blocked users. Please try again."
                isLoading = false
            }
        }
    }

    private func unblock(_ user: BlockedUser) {
        unblocking.insert(user.id)
        Task {
            do {
                try await appViewModel.dataService.unblockUser(user.id)
                await MainActor.run {
                    blocked.removeAll { $0.id == user.id }
                    unblocking.remove(user.id)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't unblock \(user.displayName). Please try again."
                    unblocking.remove(user.id)
                }
            }
        }
    }
}
