import SwiftUI

struct BadgeView: View {
    let badge: Badge
    let isEarned: Bool

    @State private var showDetail = false

    /// Cell sizing — flexible width (fills the grid column), generous height so
    /// emoji + name + pts label never clip. Previous fixed 72pt width was wider
    /// than a 6-col grid cell on iPhone screens, which is what caused the
    /// "Phoenix close to right edge" + "Star cut off on left" reports.
    var body: some View {
        VStack(spacing: 4) {
            Text(badge.emoji)
                .font(.system(size: 32))
                .opacity(isEarned ? 1.0 : 0.3)
                .frame(maxWidth: .infinity)

            Text(badge.name)
                .font(.caption2.bold())
                .foregroundStyle(isEarned ? AppTheme.textPrimary : AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(badge.pointsRequired) pts")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(.vertical, 6)
        .background(isEarned ? AppTheme.accent.opacity(0.08) : AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .strokeBorder(isEarned ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        // Tap = show detail (sentence about how to earn it + points).
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            badgeDetail
                .presentationDetents([.fraction(0.55), .medium])
                .presentationDragIndicator(.visible)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.name), \(badge.pointsRequired) points, \(isEarned ? "earned" : "not yet earned"). Tap for details.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Detail sheet

    private var badgeDetail: some View {
        VStack(spacing: 20) {
            // Large emoji at the top — fills the user's eye
            Text(badge.emoji)
                .font(.system(size: 120))
                .opacity(isEarned ? 1.0 : 0.35)
                .padding(.top, 24)

            Text(badge.name)
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)

            // Points line
            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(AppTheme.accentLime)
                Text("\(badge.pointsRequired) points")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
            }

            // Description / how to earn it
            Text(howEarnedSentence)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Earned status
            HStack(spacing: 8) {
                Image(systemName: isEarned ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(isEarned ? AppTheme.accentSage : AppTheme.textSecondary)
                Text(isEarned ? "Earned" : "Keep going — you'll get there.")
                    .font(.subheadline.bold())
                    .foregroundStyle(isEarned ? AppTheme.accentSage : AppTheme.textSecondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 18)
            .background(isEarned ? AppTheme.accentSage.opacity(0.12) : AppTheme.background)
            .clipShape(Capsule())

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
    }

    /// Fake-but-warm "how you earned this" sentence per badge tier.
    /// Combines the badge.description from the DB with concrete examples of
    /// the kinds of activities that earn points (daily login, posting,
    /// supporting others, sobriety milestones).
    private var howEarnedSentence: String {
        let base = badge.description.isEmpty
            ? "Earned at \(badge.pointsRequired) points."
            : badge.description
        let how = "You earn points by logging in daily, sharing community posts, supporting other alumni, and hitting sobriety milestones."
        return "\(base)\n\n\(how)"
    }
}
