import SwiftUI

/// The care team's inbox of open "notify my care team" alerts. Opened by tapping
/// the push notification, or reachable when a member has asked for support. Each
/// alert shows who needs help; the responder opens their chat (if on caseload)
/// and acknowledges it so the team knows it's handled.
struct CareTeamAlertsScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var alerts: [CareTeamAlert] = []
    @State private var chat = ChatViewModel()
    @State private var isLoading = false
    @State private var acknowledging: UUID?

    private func conversation(for memberId: UUID) -> Conversation? {
        chat.conversations.first { $0.userId == memberId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading && alerts.isEmpty {
                        ProgressView().padding(.top, 60)
                    } else if alerts.isEmpty {
                        emptyState
                    } else {
                        ForEach(alerts) { alert in
                            alertCard(alert)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Care Team Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func alertCard(_ alert: CareTeamAlert) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.memberName ?? "A member")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Requested care team support")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(alert.when)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                if let convo = conversation(for: alert.memberId) {
                    NavigationLink {
                        ChatDetailScreen(
                            staffName: convo.staffName,   // carries the member's name in the staff view
                            staffRole: convo.staffRole,
                            conversationId: convo.id
                        )
                    } label: {
                        Label("Open chat", systemImage: "message.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(AppTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                } else {
                    Text("Not on your caseload")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button {
                    Task { await acknowledge(alert) }
                } label: {
                    HStack(spacing: 4) {
                        if acknowledging == alert.id { ProgressView().controlSize(.small) }
                        Text("Acknowledge")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(AppTheme.cardBackground)
                    .foregroundStyle(AppTheme.accent)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(AppTheme.accent.opacity(0.4), lineWidth: 1))
                }
                .disabled(acknowledging != nil)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accentSage)
            Text("No open alerts")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("When a member taps “Notify my care team,” they'll appear here.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        if let fetched = try? await appViewModel.dataService.fetchCareTeamAlerts() {
            alerts = fetched
        }
        chat.loadConversations()
    }

    private func acknowledge(_ alert: CareTeamAlert) async {
        guard let uid = appViewModel.currentUser?.id else { return }
        acknowledging = alert.id
        defer { acknowledging = nil }
        do {
            try await appViewModel.dataService.acknowledgeCareTeamAlert(id: alert.id, by: uid)
            alerts.removeAll { $0.id == alert.id }
        } catch {
            CrashReportingService.shared.recordError(error, context: "CareTeamAlertsScreen.acknowledge")
        }
    }
}
