import SwiftUI
import CryptoKit

enum RecoveryProgram: String, CaseIterable, Identifiable {
    case iop = "IOP"
    case php = "PHP"
    case detox = "Detox"
    case residential = "Residential"
    case op = "OP"
    case other = "Other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iop: return "IOP (Intensive Outpatient)"
        case .php: return "PHP (Partial Hospitalization)"
        case .detox: return "Detox"
        case .residential: return "Residential"
        case .op: return "OP (Outpatient)"
        case .other: return "Other"
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
    private let lockoutDuration: TimeInterval = 900 // 15 minutes
    private let lockoutEndKey = "login_lockout_end_ts"
    private let failedAttemptsKey = "login_failed_attempts"

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
    var regFacility: Facility? = nil
    var showRegistrationSuccess = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = DefaultServices.authService) {
        self.authService = authService
        // Restore persisted lockout state so force-quit doesn't bypass it
        failedAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)
        if let ts = UserDefaults.standard.object(forKey: lockoutEndKey) as? Double {
            lockoutEndDate = Date(timeIntervalSince1970: ts)
        }
    }

    // MARK: - Login

    func login() async -> User? {
        // Rate limiting check
        if isLockedOut {
            let seconds = Int(lockoutRemaining)
            errorMessage = "Too many failed attempts. Try again in \(seconds)s."
            AuditLogger.shared.log(.loginLockout, detail: "Email-hash: \(Self.hashEmail(email))")
            return nil
        }

        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return nil
        }

        isLoading = true
        errorMessage = nil

        #if DEBUG
        // ── DEBUG FAST-PATH ──────────────────────────────────────────────────
        // Skip network auth entirely. Works on simulator AND real device,
        // regardless of build scheme or Supabase configuration.
        //   Regular user  →  any email except the two below
        //   Admin         →  admin@milton.com   (any password)
        //   Super Admin   →  super@milton.com   (any password)
        let debugUser: User
        switch email.lowercased() {
        case "admin@milton.com":  debugUser = MockData.adminUser
        case "super@milton.com":  debugUser = MockData.superAdminUser
        default:                  debugUser = MockData.currentUser
        }
        await MainActor.run {
            failedAttempts = 0
            lockoutEndDate = nil
            pendingUser = debugUser
            showTwoFactor = true
            isLoading = false
        }
        return debugUser
        // ────────────────────────────────────────────────────────────────────
        #else
        do {
            let user = try await authService.login(email: email, password: password)

            // Send SMS OTP to the user's phone
            try await authService.sendSMSOTP(userId: user.id)

            await MainActor.run {
                failedAttempts = 0
                lockoutEndDate = nil
                // Clear persisted lockout on successful login
                UserDefaults.standard.removeObject(forKey: lockoutEndKey)
                UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
                pendingUser = user
                showTwoFactor = true
                isLoading = false
            }
            return user
        } catch {
            await MainActor.run {
                failedAttempts += 1
                AuditLogger.shared.log(.loginFailed, detail: "Email-hash: \(Self.hashEmail(email)), attempt: \(failedAttempts)")
                if failedAttempts >= maxAttempts {
                    lockoutEndDate = Date().addingTimeInterval(lockoutDuration)
                    // Persist lockout so force-quit can't bypass it
                    UserDefaults.standard.set(lockoutEndDate?.timeIntervalSince1970, forKey: lockoutEndKey)
                    UserDefaults.standard.set(failedAttempts, forKey: failedAttemptsKey)
                    errorMessage = "Too many failed attempts. Try again in 15 minutes."
                    AuditLogger.shared.log(.loginLockout, detail: "Email-hash: \(Self.hashEmail(email))")
                } else {
                    UserDefaults.standard.set(failedAttempts, forKey: failedAttemptsKey)
                    errorMessage = "Invalid email or password. Please try again."
                }
                isLoading = false
            }
            return nil
        }
        #endif
    }

    // MARK: - 2FA Verification

    func verifyTwoFactor() async -> User? {
        guard let user = pendingUser else { return nil }

        isLoading = true
        errorMessage = nil

        #if DEBUG
        // DEBUG: accept any 6-digit code instantly — no network call needed.
        guard twoFactorCode.count == 6, twoFactorCode.allSatisfy(\.isNumber) else {
            await MainActor.run {
                errorMessage = "Enter any 6-digit code to continue."
                isLoading = false
            }
            return nil
        }
        await MainActor.run { isLoading = false }
        return user
        #else
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
        #endif
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

        guard regFacility != nil else {
            errorMessage = "Please select your facility (Florida or Ohio)."
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
                username: regUsername.trimmingCharacters(in: .whitespacesAndNewlines),
                email: regEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: regPhone.trimmingCharacters(in: .whitespacesAndNewlines),
                password: regPassword,
                sobrietyDate: regSobrietyDate,
                dischargeDate: regDischargeDate,
                recoveryProgram: regRecoveryProgram.displayName,
                facility: regFacility
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
            CrashReportingService.shared.recordError(error, context: "LoginViewModel.register")
            await MainActor.run {
                errorMessage = "Registration failed. Please try again."
                isLoading = false
            }
            return nil
        }
    }

    // MARK: - Password Reset

    var showForgotPassword = false
    var resetEmail = ""
    var isResettingPassword = false
    var passwordResetSent = false

    func sendPasswordReset() async {
        let email = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        isResettingPassword = true
        errorMessage = nil
        do {
            try await authService.resetPassword(email: email)
            await MainActor.run {
                passwordResetSent = true
                isResettingPassword = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Could not send reset email. Please check your address and try again."
                isResettingPassword = false
            }
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

    /// SHA-256 hash of email (lowercased + trimmed) for audit logging without
    /// exposing the email plaintext. Per HIPAA's minimum necessary rule we don't
    /// need the literal email in audit_logs to identify a lockout — a stable
    /// hash plus user_id (filled in by AuditLogger) is enough to correlate.
    static func hashEmail(_ email: String) -> String {
        let normalised = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let data = Data(normalised.utf8)
        let digest = SHA256.hash(data: data)
        // First 12 hex chars are enough to uniquely identify within Milton's user base;
        // keeps the audit row compact and harder to brute-force back to email.
        return digest.compactMap { String(format: "%02x", $0) }.prefix(12).joined()
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
        UserDefaults.standard.removeObject(forKey: lockoutEndKey)
        UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
    }
}
