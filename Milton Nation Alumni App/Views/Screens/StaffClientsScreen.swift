import SwiftUI

/// The home screen for clinical staff (case managers / therapists / counselors).
/// Unlike the alumni experience, staff do NOT see a personal recovery journey —
/// they see their caseload: every client assigned to them, tappable straight
/// into that client's conversation. This is the "go to chat, see all your
/// clients" view.
struct StaffClientsScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = ChatViewModel()

    private var staffName: String {
        appViewModel.currentUser?.firstName ?? "there"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if viewModel.conversations.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.conversations) { convo in
                            NavigationLink {
                                ChatDetailScreen(
                                    staffName: convo.staffName,   // carries the CLIENT name
                                    staffRole: convo.staffRole,
                                    conversationId: convo.id
                                )
                            } label: {
                                clientRow(convo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appViewModel.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            viewModel.currentUserId = appViewModel.currentUser?.id
            viewModel.loadCaseload()
        }
        .refreshable {
            viewModel.loadCaseload()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My Clients")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Welcome back, \(staffName)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            if !viewModel.conversations.isEmpty {
                Text("\(viewModel.conversations.count) assigned")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("No clients assigned yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
            Text("An admin assigns alumni to your caseload. Once assigned, they'll appear here and you can message them directly.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func clientRow(_ convo: Conversation) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(initials(convo.staffName))
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(convo.staffName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(convo.lastMessage ?? "No messages yet")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if convo.unreadCount > 0 {
                Text("\(convo.unreadCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }
}
