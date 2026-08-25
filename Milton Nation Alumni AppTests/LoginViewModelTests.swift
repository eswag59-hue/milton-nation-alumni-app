import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("LoginViewModel Tests")
struct LoginViewModelTests {

    // MARK: - Login Validation

    @Test("login fails with empty email")
    func loginEmptyEmail() async {
        let vm = LoginViewModel()
        vm.email = ""
        vm.password = "password123"
        let result = await vm.login()
        #expect(result == nil)
        #expect(vm.errorMessage == "Please enter your email and password.")
    }

    @Test("login fails with empty password")
    func loginEmptyPassword() async {
        let vm = LoginViewModel()
        vm.email = "test@example.com"
        vm.password = ""
        let result = await vm.login()
        #expect(result == nil)
        #expect(vm.errorMessage == "Please enter your email and password.")
    }

    @Test("login fails with whitespace-only email")
    func loginWhitespaceEmail() async {
        let vm = LoginViewModel()
        vm.email = "   "
        vm.password = "password123"
        let result = await vm.login()
        #expect(result == nil)
        #expect(vm.errorMessage == "Please enter your email and password.")
    }

    @Test("login succeeds with valid credentials and shows 2FA")
    func loginSuccessShows2FA() async {
        let vm = LoginViewModel()
        vm.email = "test@example.com"
        vm.password = "password123"
        let result = await vm.login()
        #expect(result != nil)
        #expect(vm.showTwoFactor == true)
        #expect(vm.pendingUser != nil)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - 2FA Verification

    @Test("verifyTwoFactor fails without pending user")
    func verifyWithoutPendingUser() async {
        let vm = LoginViewModel()
        let result = await vm.verifyTwoFactor()
        #expect(result == nil)
    }

    @Test("verifyTwoFactor succeeds with valid 6-digit code")
    func verifyWithValidCode() async {
        let vm = LoginViewModel()
        vm.email = "test@example.com"
        vm.password = "password123"
        _ = await vm.login()

        vm.twoFactorCode = "123456"
        let result = await vm.verifyTwoFactor()
        #expect(result != nil)
    }

    @Test("verifyTwoFactor fails with non-numeric code")
    func verifyWithNonNumericCode() async {
        let vm = LoginViewModel()
        vm.email = "test@example.com"
        vm.password = "password123"
        _ = await vm.login()

        vm.twoFactorCode = "abcdef"
        let result = await vm.verifyTwoFactor()
        #expect(result == nil)
        #expect(vm.errorMessage != nil)
    }

    @Test("verifyTwoFactor fails with wrong length code")
    func verifyWithWrongLengthCode() async {
        let vm = LoginViewModel()
        vm.email = "test@example.com"
        vm.password = "password123"
        _ = await vm.login()

        vm.twoFactorCode = "123"
        let result = await vm.verifyTwoFactor()
        #expect(result == nil)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Registration Validation

    @Test("register fails with empty fields")
    func registerEmptyFields() async {
        let vm = LoginViewModel()
        vm.isRegistering = true
        let result = await vm.register()
        #expect(result == nil)
        #expect(vm.errorMessage == "Please fill in all required fields.")
    }

    @Test("register fails when username contains real name")
    func registerUsernameContainsRealName() async {
        let vm = LoginViewModel()
        vm.regFullName = "John Smith"
        vm.regUsername = "john_cool"
        vm.regEmail = "john@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "password123"
        vm.regConfirmPassword = "password123"
        vm.regFacility = .florida
        vm.regAgreedToTerms = true
        let result = await vm.register()
        #expect(result == nil)
        #expect(vm.errorMessage == "Username cannot contain your real name.")
    }

    @Test("register fails when Terms not agreed")
    func registerRequiresConsent() async {
        let vm = LoginViewModel()
        vm.regFullName = "Test User"
        vm.regUsername = "recovery_hero"
        vm.regEmail = "test@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "password123"
        vm.regConfirmPassword = "password123"
        vm.regFacility = .florida
        vm.regAgreedToTerms = false
        let result = await vm.register()
        #expect(result == nil)
        #expect(vm.errorMessage == "Please agree to the Terms of Use and Privacy Policy to continue.")
    }

    @Test("register fails when username contains last name")
    func registerUsernameContainsLastName() async {
        let vm = LoginViewModel()
        vm.regFullName = "John Smith"
        vm.regUsername = "cool_smith"
        vm.regEmail = "john@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "password123"
        vm.regConfirmPassword = "password123"
        vm.regFacility = .florida
        vm.regAgreedToTerms = true
        let result = await vm.register()
        #expect(result == nil)
        #expect(vm.errorMessage == "Username cannot contain your real name.")
    }

    @Test("register allows username that doesn't contain name")
    func registerUsernameDoesNotContainName() async {
        let vm = LoginViewModel()
        vm.regFullName = "John Smith"
        vm.regUsername = "recovery_warrior"
        vm.regEmail = "john@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "password123"
        vm.regConfirmPassword = "password123"
        vm.regFacility = .florida
        vm.regAgreedToTerms = true
        let result = await vm.register()
        #expect(result != nil)
    }

    @Test("register fails when passwords don't match")
    func registerPasswordMismatch() async {
        let vm = LoginViewModel()
        vm.regFullName = "Test User"
        vm.regUsername = "recovery_hero"
        vm.regEmail = "test@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "password123"
        vm.regConfirmPassword = "different456"
        vm.regFacility = .florida
        vm.regAgreedToTerms = true
        let result = await vm.register()
        #expect(result == nil)
        #expect(vm.errorMessage == "Passwords do not match.")
    }

    @Test("register fails when password is too short")
    func registerPasswordTooShort() async {
        let vm = LoginViewModel()
        vm.regFullName = "Test User"
        vm.regUsername = "recovery_hero"
        vm.regEmail = "test@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "short"
        vm.regConfirmPassword = "short"
        vm.regFacility = .florida
        vm.regAgreedToTerms = true
        let result = await vm.register()
        #expect(result == nil)
        #expect(vm.errorMessage == "Password must be at least 8 characters.")
    }

    @Test("register succeeds with valid fields")
    func registerSuccess() async {
        let vm = LoginViewModel()
        vm.regFullName = "Test User"
        vm.regUsername = "recovery_hero"
        vm.regEmail = "test@example.com"
        vm.regPhone = "(555) 123-4567"
        vm.regPassword = "password123"
        vm.regConfirmPassword = "password123"
        vm.regFacility = .florida
        vm.regAgreedToTerms = true
        let result = await vm.register()
        #expect(result != nil)
        #expect(vm.showRegistrationSuccess == true)
    }

    // MARK: - Reset Form

    @Test("resetForm clears all login state")
    func resetFormClearsState() {
        let vm = LoginViewModel()
        vm.email = "test@test.com"
        vm.password = "pass"
        vm.twoFactorCode = "123456"
        vm.errorMessage = "Some error"
        vm.showTwoFactor = true

        vm.resetForm()

        #expect(vm.email.isEmpty)
        #expect(vm.password.isEmpty)
        #expect(vm.twoFactorCode.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.showTwoFactor == false)
        #expect(vm.pendingUser == nil)
    }

    // MARK: - Lockout Expiry
    //
    // Regression coverage for a lockout that never let go: `failedAttempts` was
    // persisted and cleared only on a *successful* login, so old failures kept
    // accumulating for the life of the install. Once the count reached 5 the
    // 15-minute lockout expired by date, but the counter stayed at 5 — leaving
    // every later single mistyped password an instant re-lock.

    private func clearLockoutDefaults() {
        for key in ["login_lockout_end_ts", "login_failed_attempts", "login_last_failed_ts"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("a served lockout resets the failure count instead of re-locking")
    func servedLockoutResetsCount() {
        clearLockoutDefaults()
        defer { clearLockoutDefaults() }

        // A lockout that ended a minute ago, with the streak that caused it.
        let ended = Date().addingTimeInterval(-60).timeIntervalSince1970
        UserDefaults.standard.set(ended, forKey: "login_lockout_end_ts")
        UserDefaults.standard.set(5, forKey: "login_failed_attempts")

        let vm = LoginViewModel()
        #expect(vm.isLockedOut == false)
        #expect(vm.failedAttempts == 0, "a served lockout must not leave the count at the threshold")
    }

    @Test("a cold failure streak expires")
    func coldStreakExpires() {
        clearLockoutDefaults()
        defer { clearLockoutDefaults() }

        // Four failures from an hour ago — well outside the attempt window.
        UserDefaults.standard.set(4, forKey: "login_failed_attempts")
        UserDefaults.standard.set(Date().addingTimeInterval(-3600).timeIntervalSince1970,
                                  forKey: "login_last_failed_ts")

        let vm = LoginViewModel()
        #expect(vm.failedAttempts == 0, "failures from an hour ago must not count toward today's lockout")
    }

    @Test("a recent failure streak is preserved")
    func recentStreakPreserved() {
        clearLockoutDefaults()
        defer { clearLockoutDefaults() }

        // Three failures a minute ago — still inside the window, still counted.
        UserDefaults.standard.set(3, forKey: "login_failed_attempts")
        UserDefaults.standard.set(Date().addingTimeInterval(-60).timeIntervalSince1970,
                                  forKey: "login_last_failed_ts")

        let vm = LoginViewModel()
        #expect(vm.failedAttempts == 3, "recent failures must still count — the rate limit has to work")
    }

    @Test("an unexpired lockout is still enforced")
    func activeLockoutEnforced() {
        clearLockoutDefaults()
        defer { clearLockoutDefaults() }

        UserDefaults.standard.set(Date().addingTimeInterval(300).timeIntervalSince1970,
                                  forKey: "login_lockout_end_ts")
        UserDefaults.standard.set(5, forKey: "login_failed_attempts")

        let vm = LoginViewModel()
        #expect(vm.isLockedOut == true, "a live lockout must survive a relaunch")
        #expect(vm.failedAttempts == 5)
    }
}
