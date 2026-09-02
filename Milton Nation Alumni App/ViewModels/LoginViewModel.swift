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
    private let lastFailedAtKey = "login_last_failed_ts"
    /// A failure older than this no longer counts toward the lockout. Without a
    /// window the counter is cumulative for the life of the install: five
    /// mistyped passwords spread over months would leave a member permanently
    /// one typo away from a 15-minute lockout.
    private let attemptWindow: TimeInterval = 900 // 15 minutes

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
    /// Required consent to Terms of Use + Privacy Policy (Apple Guideline 1.2 /
    /// EULA acceptance). The Register button stays disabled until this is true.
    var regAgreedToTerms = false
    var showRegistrationSuccess = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = DefaultServices.authService) {
        self.authService = authService
        // Restore persisted lockout state so force-quit doesn't bypass it
        failedAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)
        if let ts = UserDefaults.standard.object(forKey: lockoutEndKey) as? Double {
            lockoutEndDate = Date(timeIntervalSince1970: ts)
        }
        expireStaleAttempts()
    }

    /// Drops a served lockout and any failure streak that has gone cold, so the
    /// counter reflects *recent* activity rather than the install's whole life.
    private func expireStaleAttempts() {
        // A lockout that has already elapsed is finished — clear it along with
        // the streak that caused it, otherwise the very next failure re-locks.
        if let end = lockoutEndDate, Date() >= end {
            lockoutEndDate = nil
            failedAttempts = 0
            UserDefaults.standard.removeObject(forKey: lockoutEndKey)
            UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
            UserDefaults.standard.removeObject(forKey: lastFailedAtKey)
            return
        }
        // Not locked out, but the last failure is old — start the count fresh.
        guard lockoutEndDate == nil, failedAttempts > 0 else { return }
        let lastFailed = UserDefaults.standard.object(forKey: lastFailedAtKey) as? Double
        if let lastFailed {
            guard Date().timeIntervalSince1970 - lastFailed >= attemptWindow else { return }
        }
        // No recorded timestamp means the streak predates this fix — clear it.
        failedAttempts = 0
        UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
        UserDefaults.standard.removeObject(forKey: lastFailedAtKey)
    }

    // MARK: - Login

    func login() async -> User? {
        // Retire a served lockout / cold streak before judging this attempt —
        // the app can sit open for hours between tries.
        expireStaleAttempts()

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
        //   Regular user  →  any email except the ones below
        //   Admin         →  admin@milton.com     (any password)
        //   Super Admin   →  super@milton.com     (any password)
        //   Therapist     →  therapist@milton.com (any password)
        //   Case Manager  →  case@milton.com      (any password)
        //   Counselor     →  counselor@milton.com (any password)
        let debugUser: User
        switch email.lowercased() {
        case "admin@milton.com":      debugUser = MockData.adminUser
        case "super@milton.com":      debugUser = MockData.superAdminUser
        case "therapist@milton.com":  debugUser = MockData.therapist
        case "case@milton.com":       debugUser = MockData.caseManager
        case "counselor@milton.com":  debugUser = MockData.counselor
        default:                      debugUser = MockData.currentUser
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
                UserDefaults.standard.removeObject(forKey: lastFailedAtKey)
                pendingUser = user
                showTwoFactor = true
                isLoading = false
            }
            return user
        } catch {
            // A network failure (airplane mode / no signal) is NOT a wrong
            // password — show a connection message and don't count it as a
            // failed attempt (otherwise being offline can trigger the lockout).
            if Self.isNetworkError(error) {
                await MainActor.run {
                    errorMessage = "No internet connection. Please connect and try again."
                    isLoading = false
                }
                return nil
            }
            await MainActor.run {
                failedAttempts += 1
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFailedAtKey)
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

        // Apple Guideline 1.2: explicit agreement to Terms + Privacy is required
        // before an account can be created. The Register button is disabled
        // until this is true; this guard is defense-in-depth.
        guard regAgreedToTerms else {
            errorMessage = "Please agree to the Terms of Use and Privacy Policy to continue."
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
                // Surface the ACTUAL reason (weak password, email already used,
                // etc.) instead of a generic "try again" the user can't act on.
                let raw = error.localizedDescription.lowercased()
                if raw.contains("weak") || raw.contains("easy to guess") || raw.contains("pwned") {
                    errorMessage = "That password is too weak or has appeared in a breach. Please choose a stronger, unique password."
                } else if raw.contains("already registered") || raw.contains("already been registered") || raw.contains("user already") {
                    errorMessage = "An account with this email already exists. Try logging in instead."
                } else if raw.contains("valid email") || raw.contains("invalid") && raw.contains("email") {
                    errorMessage = "Please enter a valid email address."
                } else {
                    errorMessage = "Registration failed: \(error.localizedDescription)"
                }
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
    /// True when an error is a connectivity failure (offline / no signal),
    /// as opposed to a real auth rejection. Covers URLError and the wrapped
    /// URLErrors that Supabase/GoTrue surface.
    static func isNetworkError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut,
                 .cannotConnectToHost, .cannotFindHost, .dataNotAllowed,
                 .internationalRoamingOff:
                return true
            default: break
            }
        }
        let text = error.localizedDescription.lowercased()
        return text.contains("offline")
            || text.contains("internet connection")
            || text.contains("network connection")
            || text.contains("could not connect")
            || text.contains("appears to be offline")
    }

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
        // Clear the consent checkbox so a fresh registration starts unchecked.
        regAgreedToTerms = false
        UserDefaults.standard.removeObject(forKey: lockoutEndKey)
        UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
    }
}
