import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("AuthService Tests")
struct AuthServiceTests {

    // MARK: - Login

    @Test("login with default email returns alumni user")
    func loginDefaultReturnsAlumni() async throws {
        let service = MockAuthService()
        let user = try await service.login(email: "user@example.com", password: "password")
        #expect(user.role == .alumni)
    }

    @Test("login with admin email returns admin user")
    func loginAdminEmail() async throws {
        let service = MockAuthService()
        let user = try await service.login(email: "admin@milton.com", password: "password")
        #expect(user.role == .admin)
    }

    @Test("login with super admin email returns super admin user")
    func loginSuperAdminEmail() async throws {
        let service = MockAuthService()
        let user = try await service.login(email: "super@milton.com", password: "password")
        #expect(user.role == .superAdmin)
    }

    @Test("login is case-insensitive for email")
    func loginCaseInsensitive() async throws {
        let service = MockAuthService()
        let user = try await service.login(email: "ADMIN@MILTON.COM", password: "password")
        #expect(user.role == .admin)
    }

    // MARK: - MFA Verification

    @Test("verifyMFA succeeds with valid 6-digit code")
    func verifyMFAValid() async throws {
        let service = MockAuthService()
        let loginUser = try await service.login(email: "test@example.com", password: "pass")
        let verified = try await service.verifyMFA(userId: loginUser.id, code: "123456")
        #expect(verified.id == loginUser.id)
    }

    @Test("verifyMFA fails with non-numeric code")
    func verifyMFANonNumeric() async throws {
        let service = MockAuthService()
        let loginUser = try await service.login(email: "test@example.com", password: "pass")

        do {
            _ = try await service.verifyMFA(userId: loginUser.id, code: "abcdef")
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    @Test("verifyMFA fails with wrong length code")
    func verifyMFAWrongLength() async throws {
        let service = MockAuthService()
        let loginUser = try await service.login(email: "test@example.com", password: "pass")

        do {
            _ = try await service.verifyMFA(userId: loginUser.id, code: "12345")
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    @Test("verifyMFA fails with wrong user ID")
    func verifyMFAWrongUser() async throws {
        let service = MockAuthService()
        _ = try await service.login(email: "test@example.com", password: "pass")

        do {
            _ = try await service.verifyMFA(userId: UUID(), code: "123456")
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    // MARK: - Logout

    @Test("logout clears current user")
    func logoutClearsUser() async throws {
        let service = MockAuthService()
        _ = try await service.login(email: "test@example.com", password: "pass")
        #expect(service.getCurrentUser() != nil)

        try await service.logout()
        #expect(service.getCurrentUser() == nil)
    }

    // MARK: - Registration

    @Test("register creates a new alumni user with pending status")
    func registerCreatesAlumni() async throws {
        let service = MockAuthService()
        let user = try await service.register(
            fullName: "New User",
            email: "new@example.com",
            phone: "(555) 111-2222",
            password: "password123",
            sobrietyDate: Date(),
            dischargeDate: Date(),
            recoveryProgram: "IOP"
        )

        #expect(user.role == .alumni)
        #expect(user.status == .pending)
        #expect(user.fullName == "New User")
        #expect(user.email == "new@example.com")
    }
}
