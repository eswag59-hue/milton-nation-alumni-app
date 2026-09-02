import Foundation

/// Controls the narrow, deliberate exemption to `ScreenshotProtection`.
///
/// The app blocks screen recording, AirPlay mirroring, and QuickTime capture to
/// keep PHI off marketing reels, support tickets, and shoulder-surfers. That
/// protection is unchanged for every real member.
///
/// It lifts in exactly one case: while one of the seeded, PHI-free **demo**
/// accounts below is signed in. Those accounts contain only fabricated content
/// (Alex Demo, Dana Case, Dr. Robin Nova, …), so recording them exposes nothing
/// about a real person — and it lets the team capture the genuine app for
/// marketing instead of rebuilding its screens by hand.
///
/// The allowlist is intentionally explicit rather than a role or flag check:
/// a real alumnus, admin, or clinician can never satisfy it, even by accident.
enum MarketingCapture {

    /// Seeded demo accounts that hold no PHI.
    private static let allowedEmails: Set<String> = [
        "appreviewer@miltonrecovery.com",
        "super-demo@miltonrecovery.com",
        "case-manager-demo@miltonrecovery.com",
        "therapist-demo@miltonrecovery.com",
        // DEBUG mock logins (mock data only, never reach production auth)
        "admin@milton.com",
        "super@milton.com",
        "therapist@milton.com",
        "case@milton.com",
        "counselor@milton.com",
    ]

    /// Domain used by the seeded demo alumni (`*.@miltondemo.seed`).
    private static let allowedDomainSuffix = "@miltondemo.seed"

    /// Whether screen capture is currently permitted. Defaults to `false`, and
    /// returns to `false` on logout, so the protection is on unless explicitly
    /// and provably safe.
    private(set) static var isEnabled = false

    /// Called on every login and logout. Passing `nil` re-arms the block.
    static func update(for user: User?) {
        guard let email = user?.email.lowercased(), !email.isEmpty else {
            isEnabled = false
            return
        }
        isEnabled = allowedEmails.contains(email) || email.hasSuffix(allowedDomainSuffix)
    }
}
