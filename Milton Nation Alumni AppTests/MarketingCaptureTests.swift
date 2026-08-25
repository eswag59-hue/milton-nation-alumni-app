import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

/// The screen-capture exemption is a deliberate hole in a PHI protection, so it
/// gets its own tests: real members must NEVER be capturable, no matter their
/// role, and the block must re-arm on logout.
@Suite("MarketingCapture Tests")
struct MarketingCaptureTests {

    private func user(_ email: String, role: UserRole = .alumni) -> User {
        User(
            id: UUID(),
            email: email,
            phone: "(555) 000-0000",
            fullName: "Test User",
            username: "test_user",
            profilePhotoURL: nil,
            sobrietyDate: Date(),
            dischargeDate: Date(),
            recoveryProgram: "Test Program",
            role: role,
            status: .active,
            mfaMethod: .sms,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - The protection holds for real people

    @Test("a real alumnus is never capturable")
    func realAlumnusBlocked() {
        MarketingCapture.update(for: user("jane.doe@gmail.com"))
        #expect(MarketingCapture.isEnabled == false)
    }

    @Test("privileged roles are not capturable either")
    func privilegedRolesBlocked() {
        for role in [UserRole.admin, .superAdmin, .therapist, .caseManager, .counselor] {
            MarketingCapture.update(for: user("real.staff@miltonrecovery.com", role: role))
            #expect(MarketingCapture.isEnabled == false, "role \(role.rawValue) must not lift the block")
        }
    }

    @Test("a lookalike address does not satisfy the allowlist")
    func lookalikeAddressBlocked() {
        // Same local part, attacker-controlled domain.
        MarketingCapture.update(for: user("appreviewer@evil.com"))
        #expect(MarketingCapture.isEnabled == false)

        // Demo domain as a prefix rather than the actual suffix.
        MarketingCapture.update(for: user("someone@miltondemo.seed.evil.com"))
        #expect(MarketingCapture.isEnabled == false)
    }

    @Test("an empty or missing email leaves the block armed")
    func emptyEmailBlocked() {
        MarketingCapture.update(for: user(""))
        #expect(MarketingCapture.isEnabled == false)

        MarketingCapture.update(for: nil)
        #expect(MarketingCapture.isEnabled == false)
    }

    // MARK: - The exemption works for demo accounts

    @Test("seeded demo accounts are capturable")
    func demoAccountsAllowed() {
        for email in ["appreviewer@miltonrecovery.com",
                      "super-demo@miltonrecovery.com",
                      "case-manager-demo@miltonrecovery.com",
                      "therapist-demo@miltonrecovery.com",
                      "recovery.warrior@miltondemo.seed"] {
            MarketingCapture.update(for: user(email))
            #expect(MarketingCapture.isEnabled == true, "\(email) should allow capture")
        }
    }

    @Test("the allowlist is case-insensitive")
    func caseInsensitive() {
        MarketingCapture.update(for: user("AppReviewer@MiltonRecovery.com"))
        #expect(MarketingCapture.isEnabled == true)
    }

    // MARK: - Lifecycle

    @Test("logging out re-arms the block")
    func logoutRearmsBlock() {
        MarketingCapture.update(for: user("appreviewer@miltonrecovery.com"))
        #expect(MarketingCapture.isEnabled == true)

        MarketingCapture.update(for: nil)
        #expect(MarketingCapture.isEnabled == false)
    }

    @Test("switching from a demo account to a real one re-arms the block")
    func switchingUsersRearmsBlock() {
        MarketingCapture.update(for: user("appreviewer@miltonrecovery.com"))
        #expect(MarketingCapture.isEnabled == true)

        MarketingCapture.update(for: user("jane.doe@gmail.com"))
        #expect(MarketingCapture.isEnabled == false)
    }
}
