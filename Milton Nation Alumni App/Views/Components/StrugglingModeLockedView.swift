import SwiftUI

struct StrugglingModeLockedView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var showExitConfirmation = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.struggling)

            Text("You're in Struggle Mode")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            Text("We've limited the app so you can focus on getting support. Your care team is ready to help.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    appViewModel.selectedTab = .chat
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Chat with Your Care Team")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .accessibilityLabel("Chat with your care team")
                .accessibilityHint("Double tap to open chat")

                Button {
                    // Crisis lines and care-team contacts live in ChatListScreen (Chat tab)
                    appViewModel.selectedTab = .chat
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("View Crisis Lines & Contacts")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(AppTheme.struggling)
                    .background(AppTheme.strugglingLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .accessibilityLabel("View crisis lines and contacts")
                .accessibilityHint("Double tap to open chat and crisis phone numbers")

                Button {
                    showExitConfirmation = true
                } label: {
                    Text("Exit Struggle Mode")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("Exit struggle mode")
                .accessibilityHint("Double tap to return to full app access")
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background)
        .alert("Exit Struggle Mode?", isPresented: $showExitConfirmation) {
            Button("Stay in Struggle Mode", role: .cancel) {}
            Button("Exit") {
                appViewModel.exitStrugglingMode()
            }
        } message: {
            Text("Are you sure you're feeling better? You can re-enter Struggle Mode anytime from the home screen.")
        }
    }
}
