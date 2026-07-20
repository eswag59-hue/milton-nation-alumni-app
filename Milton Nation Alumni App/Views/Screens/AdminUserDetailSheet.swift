import SwiftUI

/// Read-only detail view for a single member, opened by tapping a row in the
/// admin User Management list. Promotion still runs through AdminViewModel so
/// the confirmation dialog and audit logging behave identically to the inline
/// button on the list row.
struct AdminUserDetailSheet: View {
    let user: User
    var viewModel: AdminViewModel

    @Environment(\.dismiss) private var dismiss

    private var daysSober: Int {
        max(0, Calendar.current.dateComponents([.day], from: user.sobrietyDate, to: Date()).day ?? 0)
    }

    private var roleColor: Color {
        switch user.role {
        case .superAdmin: return AppTheme.primary
        case .admin: return AppTheme.primaryMedium
        case .caseManager, .therapist, .counselor: return AppTheme.accent
        default: return AppTheme.textSecondary
        }
    }

    private var roleIcon: String {
        switch user.role {
        case .superAdmin: return "crown.fill"
        case .admin: return "person.badge.key"
        case .caseManager, .therapist, .counselor: return "stethoscope"
        default: return "person.fill"
        }
    }

    private var statusColor: Color {
        switch user.status {
        case .active: return .green
        case .pending: return .orange
        default: return .red
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    detailCard("Contact", rows: [
                        ("envelope.fill", "Email", user.email),
                        ("phone.fill", "Phone", user.phone.isEmpty ? "—" : user.phone),
                        ("at", "Username", user.username.isEmpty ? "—" : "@\(user.username)")
                    ])

                    detailCard("Recovery", rows: [
                        ("calendar", "Sobriety date", Self.dateText(user.sobrietyDate)),
                        ("flame.fill", "Days sober", "\(daysSober)"),
                        ("figure.walk.departure", "Discharge date", Self.dateText(user.dischargeDate)),
                        ("heart.text.square.fill", "Program",
                         user.recoveryProgram.isEmpty ? "—" : user.recoveryProgram)
                    ])

                    detailCard("Account", rows: [
                        ("building.2.fill", "Facility", user.facility?.displayName ?? "Not set"),
                        ("checkmark.seal.fill", "Status", user.status.rawValue.capitalized),
                        ("star.fill", "Total points", "\(user.totalPoints)"),
                        ("text.bubble.fill", "Approved posts", "\(user.approvedPostCount)"),
                        ("clock.fill", "Last login",
                         user.lastLogin.map(Self.dateText) ?? "Never"),
                        ("person.crop.circle.badge.plus", "Joined", Self.dateText(user.createdAt))
                    ])

                    if user.role == .alumni || user.role == .admin {
                        Button {
                            let promoted = user
                            dismiss()
                            // Let the sheet finish dismissing before the
                            // confirmation dialog is presented underneath it.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                viewModel.beginPromoteUser(promoted)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                Text(user.role == .admin ? "Upgrade Role" : "Promote User")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(AppTheme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("Member Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(roleColor.opacity(0.18))
                .frame(width: 76, height: 76)
                .overlay {
                    Image(systemName: roleIcon)
                        .font(.system(size: 30))
                        .foregroundStyle(roleColor)
                }

            Text(user.fullName)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                badge(user.role.displayName, color: roleColor)
                badge(user.status.rawValue.capitalized, color: statusColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .cardStyle()
        .padding(.horizontal)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func detailCard(_ title: String, rows: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: row.0)
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 18)

                    Text(row.1)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer(minLength: 12)

                    Text(row.2)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private static func dateText(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
