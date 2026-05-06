import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func sendSMSOTP(userId: UUID) async throws
    func verifyMFA(userId: UUID, code: String) async throws -> User
    func logout() async throws
    func register(fullName: String, username: String, email: String, phone: String, password: String, sobrietyDate: Date, dischargeDate: Date, recoveryProgram: String, facility: Facility?) async throws -> User
    func getCurrentUser() -> User?
    func resetPassword(email: String) async throws
}

final class MockAuthService: AuthServiceProtocol {
    private var currentUser: User? = MockData.currentUser
    private var pendingMFAUser: User?

    func login(email: String, password: String) async throws -> User {
        try? await Task.sleep(for: .milliseconds(500))

        // Role auto-detection based on email
        let user: User
        switch email.lowercased() {
        case "admin@milton.com":
            user = MockData.adminUser
        case "super@milton.com":
            user = MockData.superAdminUser
        default:
            user = MockData.currentUser
        }

        // Access control: admin/superAdmin must have .active status
        if user.role == .admin || user.role.isSuperAdmin {
            guard user.status == .active else {
                throw NSError(domain: "auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "This admin account has not been approved or is inactive."])
            }
        }

        pendingMFAUser = user
        currentUser = user
        return user
    }

    func sendSMSOTP(userId: UUID) async throws {
        // Mock: simulate sending SMS
        try? await Task.sleep(for: .milliseconds(300))
    }

    func verifyMFA(userId: UUID, code: String) async throws -> User {
        try? await Task.sleep(for: .milliseconds(300))
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"])
        }
        // Return the user that was authenticated during login
        guard let user = pendingMFAUser, user.id == userId else {
            throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "MFA session expired. Please log in again."])
        }
        currentUser = user
        pendingMFAUser = nil
        return user
    }

    func logout() async throws {
        try? await Task.sleep(for: .milliseconds(200))
        currentUser = nil
    }

    func register(fullName: String, username: String, email: String, phone: String, password: String, sobrietyDate: Date, dischargeDate: Date, recoveryProgram: String, facility: Facility?) async throws -> User {
        try? await Task.sleep(for: .milliseconds(500))
        var newUser = User(
            id: UUID(),
            email: email,
            phone: phone,
            fullName: fullName,
            username: username,
            profilePhotoURL: nil,
            sobrietyDate: sobrietyDate,
            dischargeDate: dischargeDate,
            recoveryProgram: recoveryProgram,
            role: .alumni,
            status: .pending,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        newUser.facility = facility
        return newUser
    }

    func getCurrentUser() -> User? {
        currentUser
    }

    func resetPassword(email: String) async throws {
        try? await Task.sleep(for: .milliseconds(500))
        // Mock: pretend the reset email was sent
    }
}
