import SwiftUI

struct SobrietyTrackerCard: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Journey")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            Text("\(user.daysOfRecovery)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityLabel("\(user.daysOfRecovery) days of recovery")

            Text("Days of Recovery")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)

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

            Text("Living proof that recovery works")
                .font(.footnote)
                .italic()
                .foregroundStyle(AppTheme.accent)
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
