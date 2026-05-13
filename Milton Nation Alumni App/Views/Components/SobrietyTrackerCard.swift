import SwiftUI

struct SobrietyTrackerCard: View {
    let user: User
    /// Action invoked when the user taps "Update recovery date".
    /// HomeScreen wires this to opening the SobrietyCheckModal.
    var onUpdateRecoveryDate: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 6) {
            // Big day count
            Text("\(user.daysOfRecovery)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityLabel("\(user.daysOfRecovery) days of recovery")

            // "days" label directly below the number
            Text(user.daysOfRecovery == 1 ? "day" : "days")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)

            // Tagline replaces the previous "Your Journey" / "Days of Recovery" labels
            Text("Living proof that recovery works")
                .font(.footnote)
                .italic()
                .foregroundStyle(AppTheme.accent)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            // Weeks / months / years breakdown
            HStack(spacing: 0) {
                metricBox(value: "\(user.weeksOfRecovery)", label: "weeks")
                Divider().frame(height: 40)
                metricBox(value: "\(user.monthsOfRecovery)", label: "months")
                Divider().frame(height: 40)
                metricBox(value: "\(user.yearsOfRecovery)", label: "years")
            }
            .padding(.vertical, 8)
            .background(AppTheme.background.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))

            // Update recovery date — opens the SobrietyCheckModal so the user
            // can pick a new sobriety date if they relapsed or want to correct it.
            Button {
                onUpdateRecoveryDate?()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.footnote)
                    Text("Update recovery date")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(AppTheme.accent)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Capsule())
            }
            .accessibilityHint("Opens a screen where you can pick a new sobriety date.")
        }
        .padding()
        .background(AppTheme.sobrietyGradient)
        .cardStyle()
    }

    private func metricBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
