import SwiftUI

struct BadgeView: View {
    let badge: Badge
    let isEarned: Bool

    @State private var isPressed = false

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
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .strokeBorder(isEarned ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        // Press-and-hold to enlarge. Scales the badge up 1.6x in place
        // (no sheet, no popover — the badge just grows so you can see the
        // emoji + name clearly), then springs back to normal on release.
        .scaleEffect(isPressed ? 1.6 : 1.0)
        .shadow(color: isPressed ? AppTheme.accent.opacity(0.25) : .clear,
                radius: isPressed ? 10 : 0, y: isPressed ? 4 : 0)
        .zIndex(isPressed ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .gesture(
            LongPressGesture(minimumDuration: 0.0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
                .simultaneously(with:
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in isPressed = false }
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.name) badge, \(badge.pointsRequired) points required, \(isEarned ? "earned" : "not yet earned"). Press and hold to enlarge.")
    }
}
