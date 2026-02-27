import SwiftUI

enum RecoveryProgram: String, CaseIterable, Identifiable {
    case iop = "IOP"
    case php = "PHP"
    case detox = "Detox"
    case residential = "Residential"
    case op = "OP"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iop: return "IOP (Intensive Outpatient)"
        case .php: return "PHP (Partial Hospitalization)"
        case .detox: return "Detox"
        case .residential: return "Residential"
        case .op: return "OP (Outpatient)"
        }
    }
}

@Observable
final class LoginViewModel {
    // Login fields
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    // 2FA fields
    var showTwoFactor = false
    var twoFactorCode = ""
    var pendingUser: User?

    // Rate limiting
    var failedAttempts = 0
    var lockoutEndDate: Date?
    var isLockedOut: Bool {
        guard let end = lockoutEndDate else { return false }
        return Date() < end
    }
    var lockoutRemaining: TimeInterval {
        guard let end = lockoutEndDate else { return 0 }
        return max(0, end.timeIntervalSince(Date()))
    }
    private let maxAttempts = 5
    private let lockoutDuration: TimeInterval = 30

    // Registration toggle & fields
    var isRegistering = false
    var regFullName = ""
    var regUsername = ""
    var regEmail = ""
    var regPhone = ""
    var regPassword = ""
    var regConfirmPassword = ""
    var regSobrietyDate = Date()
    var regDischargeDate = Date()
    var regRecoveryProgram: RecoveryProgram = .residential
    var showRegistrationSuccess = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
    }

    // MARK: - Login

    func login() async -> User? {
        // Rate limiting check
        if isLockedOut {
            let seconds = Int(lockoutRemaining)
            errorMessage = "Too many failed attempts. Try again in \(seconds)s."
            AuditLogger.shared.log(.loginLockout, detail: "Email: \(email)")
            return nil
        }

        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.login(email: email, password: password)

            // Send SMS OTP to the user's phone
            try await authService.sendSMSOTP(userId: user.id)

            await MainActor.run {
                failedAttempts = 0
                lockoutEndDate = nil
                pendingUser = user
                showTwoFactor = true
                isLoading = false
            }
            return user
        } catch {
            await MainActor.run {
                failedAttempts += 1
                AuditLogger.shared.log(.loginFailed, detail: "Email: \(email), attempt: \(failedAttempts)")
                if failedAttempts >= maxAttempts {
                    lockoutEndDate = Date().addingTimeInterval(lockoutDuration)
                    errorMessage = "Too many failed attempts. Try again in \(Int(lockoutDuration))s."
                    AuditLogger.shared.log(.loginLockout, detail: "Email: \(email)")
                } else {
                    errorMessage = "Invalid email or password. Please try again."
                }
                isLoading = false
            }
            return nil
        }
    }

    // MARK: - 2FA Verification

    func verifyTwoFactor() async -> User? {
        guard let user = pendingUser else { return nil }

        isLoading = true
        errorMessage = nil

        do {
            let verifiedUser = try await authService.verifyMFA(userId: user.id, code: twoFactorCode)
            await MainActor.run { isLoading = false }
            return verifiedUser
        } catch {
            await MainActor.run {
                errorMessage = "Invalid verification code. Please try again."
                isLoading = false
            }
            return nil
        }
    }

    // MARK: - Registration

    func register() async -> User? {
        guard !regFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !regUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !regEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !regPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !regPassword.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return nil
        }

        // Validate username doesn't contain real name
        let nameParts = regFullName.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
        let usernameLower = regUsername.lowercased()
        for part in nameParts {
            if part.count >= 2 && usernameLower.contains(part) {
                errorMessage = "Username cannot contain your real name."
                return nil
            }
        }

        guard regPassword == regConfirmPassword else {
            errorMessage = "Passwords do not match."
            return nil
        }

        guard regPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.register(
                fullName: regFullName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: regEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: regPhone.trimmingCharacters(in: .whitespacesAndNewlines),
                password: regPassword,
                sobrietyDate: regSobrietyDate,
                dischargeDate: regDischargeDate,
                recoveryProgram: regRecoveryProgram.displayName
            )
            await MainActor.run {
                isLoading = false
                showRegistrationSuccess = true

                // Local notification to the registering user — confirms submission
                // (Admin push is sent server-side via the send-push-notification edge function)
                PushNotificationService.shared.scheduleLocalNotification(
                    title: "Application Submitted ✓",
                    body: "Your Milton Nation application is pending review. We'll notify you once approved!",
                    userInfo: ["type": "registration_submitted"]
                )
            }
            return user
        } catch {
            await MainActor.run {
                errorMessage = "Registration failed. Please try again."
                isLoading = false
            }
            return nil
        }
    }

    // MARK: - Resend SMS OTP

    func resendSMSOTP() async {
        guard let user = pendingUser else { return }
        do {
            try await authService.sendSMSOTP(userId: user.id)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to resend code. Please try again."
            }
        }
    }

    func resetForm() {
        email = ""
        password = ""
        twoFactorCode = ""
        errorMessage = nil
        showTwoFactor = false
        pendingUser = nil
        failedAttempts = 0
        lockoutEndDate = nil
    }
}
