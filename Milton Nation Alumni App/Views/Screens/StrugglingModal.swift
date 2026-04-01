import SwiftUI

struct StrugglingModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @State private var notifyCareTeam = false
    @State private var showNotificationSent = false
    @State private var chatViewModel = ChatViewModel()
    @State private var navigateToStaff: User?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.struggling)
                        Text("You're Not Alone")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.struggling)
                        Text("Reach out to someone who can help right now.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Crisis Hotlines
                    VStack(spacing: 12) {
                        // 988 — Phone call
                        phoneRow(name: "988 Suicide & Crisis Lifeline", number: "988", icon: "phone.arrow.up.right.fill", isEmergency: true)
                        // SAMHSA — Phone call
                        phoneRow(name: "SAMHSA Helpline", number: "1-800-662-4357", icon: "phone.fill", isEmergency: true)
                        // Crisis Text Line — SMS text message
                        smsRow(name: "Crisis Text Line", number: "741741", isEmergency: true)
                    }

                    Divider()

                    // Milton contacts
                    VStack(spacing: 12) {
                        Text("Milton Team")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryMedium)
                            .clipShape(Capsule())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        phoneRow(name: "Milton Team", number: "(844) 975-4673", icon: "building.2.fill", isEmergency: false)
                    }

                    Divider()

                    // Care team (chat only — navigates to specific chat thread)
                    VStack(spacing: 12) {
                        Text("Your Care Team")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryMedium)
                            .clipShape(Capsule())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(chatViewModel.assignedStaff.filter { $0.role.isClinical }) { staff in
                            careTeamRow(staff: staff)
                        }
                    }

                    Divider()

                    // Notify toggle
                    Toggle(isOn: $notifyCareTeam) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notify your care team")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("They'll reach out to offer support")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.accent)
                    .padding()
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    .onChange(of: notifyCareTeam) {
                        if notifyCareTeam {
                            showNotificationSent = true
                        }
                    }

                    Divider()

                    // Enter Struggle Mode
                    Button {
                        appViewModel.enterStrugglingMode()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enter Struggle Mode")
                                    .font(.headline)
                                Text("Locks all tabs except Chat & Contacts so you can focus on getting help")
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(AppTheme.struggling)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                    .accessibilityLabel("Enter struggle mode")
                    .accessibilityHint("Locks app to Chat and Contacts only")
                }
                .padding()
            }
            .navigationTitle("Get Help Now")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Team Notified", isPresented: $showNotificationSent) {
                Button("OK") {}
            } message: {
                Text("Your care team has been notified and will reach out to you soon.")
            }
            .onAppear {
                chatViewModel.loadConversations()
            }
            .navigationDestination(item: $navigateToStaff) { staff in
                let conv = chatViewModel.conversations.first(where: { $0.staffId == staff.id })
                ChatDetailScreen(
                    staffName: staff.fullName,
                    staffRole: staff.role,
                    conversationId: conv?.id ?? UUID()
                )
            }
        }
    }

    // MARK: - Phone call row (opens native Phone app via tel:)

    private func phoneRow(name: String, number: String, icon: String, isEmergency: Bool) -> some View {
        Button {
            PhoneService.call(number)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isEmergency ? AppTheme.struggling : AppTheme.accent)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(number)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "phone.fill")
                    .foregroundStyle(isEmergency ? AppTheme.struggling : AppTheme.accent)
            }
            .padding()
            .background(isEmergency ? AppTheme.strugglingLight : AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
        .accessibilityLabel("Call \(name) at \(number)")
        .accessibilityHint("Double tap to call")
    }

    // MARK: - SMS text row (opens native Messages app via sms:)

    private func smsRow(name: String, number: String, isEmergency: Bool) -> some View {
        Button {
            PhoneService.text(number)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundStyle(isEmergency ? AppTheme.struggling : AppTheme.accent)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Text \(number)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "message.fill")
                    .foregroundStyle(isEmergency ? AppTheme.struggling : AppTheme.accent)
            }
            .padding()
            .background(isEmergency ? AppTheme.strugglingLight : AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
        .accessibilityLabel("Text \(name) at \(number)")
        .accessibilityHint("Double tap to send a text message")
    }

    // MARK: - Care Team Row (navigates directly to specific chat thread)

    private func careTeamRow(staff: User) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.accent.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.accent)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(staff.fullName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(staff.role.displayName)
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }
            Spacer()
            Button {
                navigateToStaff = staff
            } label: {
                Image(systemName: "message.fill")
                    .padding(10)
                    .foregroundStyle(.white)
                    .background(AppTheme.accent)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Chat with \(staff.fullName)")
            .accessibilityHint("Double tap to open direct chat")
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
    }
}
