import SwiftUI

struct BadgeView: View {
    let badge: Badge
    let isEarned: Bool
    @State private var showDetail = false

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
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            badgeDetailSheet
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.name) badge, \(badge.pointsRequired) points required, \(isEarned ? "earned" : "not yet earned"). Tap for details.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Detail Sheet

    private var badgeDetailSheet: some View {
        VStack(spacing: 20) {
            // Large emoji
            Text(badge.emoji)
                .font(.system(size: 140))
                .opacity(isEarned ? 1.0 : 0.35)
                .padding(.top, 24)

            // Badge name
            Text(badge.name)
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Points required
            Text("\(badge.pointsRequired) points")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)

            // Earned status
            HStack(spacing: 8) {
                Image(systemName: isEarned ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(isEarned ? AppTheme.accentSage : AppTheme.textSecondary)
                Text(isEarned ? "Earned!" : "Keep going — you'll get there.")
                    .font(.subheadline)
                    .foregroundStyle(isEarned ? AppTheme.accentSage : AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.background)
    }
}
