import SwiftUI

struct ChatListScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = ChatViewModel()

    private var clinicalStaff: [User] {
        viewModel.assignedStaff.filter { $0.role.isClinical }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo header
                ZStack {
                    MiltonLogoView(size: .small)
                    HStack {
                        Spacer()
                        Text("Chat")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)

                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        // Care team chats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Care Team")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 4)

                            if clinicalStaff.isEmpty {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.badge.questionmark")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("No care team assigned yet")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.textSecondary)
                                        Text("Contact an admin to get connected with your counselor or therapist.")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            } else {
                                ForEach(clinicalStaff) { staff in
                                    let conv = viewModel.conversations.first(where: { $0.staffId == staff.id })
                                    if let conversation = conv {
                                        NavigationLink {
                                            ChatDetailScreen(
                                                staffName: staff.fullName,
                                                staffRole: staff.role,
                                                conversationId: conversation.id
                                            )
                                        } label: {
                                            ContactCard(
                                                name: staff.fullName,
                                                role: staff.role.displayName,
                                                onMessage: {}
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        // Conversation not yet created — show non-navigable card with note
                                        ContactCard(
                                            name: staff.fullName,
                                            role: staff.role.displayName,
                                            onMessage: {}
                                        )
                                        .opacity(0.6)
                                        .overlay(alignment: .trailing) {
                                            Text("Pending setup")
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.textSecondary)
                                                .padding(.trailing, 12)
                                        }
                                    }
                                }
                            }
                        }

                        Divider().padding(.vertical, 4)

                        // Milton Team & Crisis contacts
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Milton Team & Crisis Lines")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 4)

                            // Milton Team — phone call
                            phoneContactRow(name: "Milton Team", number: "(844) 406-4325", icon: "building.2.fill", isCrisis: false)

                            // 988 Suicide & Crisis Lifeline — phone call
                            phoneContactRow(name: "988 Suicide & Crisis Lifeline", number: "988", icon: "phone.arrow.up.right.fill", isCrisis: true)

                            // SAMHSA Helpline — phone call
                            phoneContactRow(name: "SAMHSA Helpline", number: "1-800-662-4357", icon: "phone.fill", isCrisis: true)

                            // Crisis Text Line — SMS text message
                            smsContactRow(name: "Crisis Text Line", number: "741741", isCrisis: true)
                        }
                    }
                    .padding()
                }
            }
            .background(AppTheme.background)
            .onAppear {
                viewModel.loadConversations()
            }
        }
    }

    // MARK: - Phone call row (opens tel:)

    private func phoneContactRow(name: String, number: String, icon: String, isCrisis: Bool) -> some View {
        Button {
            PhoneService.call(number)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isCrisis ? AppTheme.struggling : AppTheme.accent)
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
                    .foregroundStyle(isCrisis ? AppTheme.struggling : AppTheme.accent)
            }
            .padding()
            .background(isCrisis ? AppTheme.strugglingLight : AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
    }

    // MARK: - SMS text row (opens Messages app via sms://)

    private func smsContactRow(name: String, number: String, isCrisis: Bool) -> some View {
        Button {
            PhoneService.text(number)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundStyle(isCrisis ? AppTheme.struggling : AppTheme.accent)
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
                    .foregroundStyle(isCrisis ? AppTheme.struggling : AppTheme.accent)
            }
            .padding()
            .background(isCrisis ? AppTheme.strugglingLight : AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
    }
}
