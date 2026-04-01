import SwiftUI

/// Shown to users whose account is in `pending` status — awaiting admin facility assignment & approval.
/// Disappears automatically once an admin approves the account (AppViewModel.currentUser.status updates
/// via the Realtime subscription started in AppViewModel.login()).
struct PendingApprovalScreen: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            MiltonLogoView(size: .large)

            // Status illustration
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.badge.clock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accent)
            }

            // Heading
            VStack(spacing: 8) {
                Text("Application Under Review")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your account is waiting for an admin to confirm your facility and activate your profile.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Facility badge (shows what the user self-selected at registration)
            if let facility = appViewModel.currentUser?.facility {
                HStack(spacing: 8) {
                    Text(facility.emoji)
                    Text("Applied for: \(facility.displayName) Community")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Capsule())
            }

            // What happens next
            VStack(alignment: .leading, spacing: 12) {
                pendingStep(icon: "bell.fill", text: "You'll receive a push notification the moment you're approved.")
                pendingStep(icon: "person.2.fill", text: "You'll gain access to your community's posts, meetings, and chat.")
                pendingStep(icon: "checkmark.seal.fill", text: "This usually happens within 24 hours.")
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .padding(.horizontal, 24)

            Spacer()

            // Logout
            Button {
                appViewModel.logout()
            } label: {
                Text("Log Out")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func pendingStep(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
