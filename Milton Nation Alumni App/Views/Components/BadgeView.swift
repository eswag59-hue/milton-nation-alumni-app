import SwiftUI

struct BadgeView: View {
    let badge: Badge
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(badge.emoji)
                .font(.system(size: 36))
                .opacity(isEarned ? 1.0 : 0.3)

            Text(badge.name)
                .font(.caption2.bold())
                .foregroundStyle(isEarned ? AppTheme.textPrimary : AppTheme.textSecondary)

            Text("\(badge.pointsRequired) pts")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(width: 72, height: 90)
        .background(isEarned ? AppTheme.accent.opacity(0.08) : AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall).strokeBorder(isEarned ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.name) badge, \(badge.pointsRequired) points required, \(isEarned ? "earned" : "not yet earned")")
    }
}
