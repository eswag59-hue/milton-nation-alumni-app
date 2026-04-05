import Foundation
import LocalAuthentication

/// HIPAA Technical Safeguard — Device Security Verification
///
/// Checks:
///   1. Device passcode / biometric lock is enabled (required — PHI accessible if device unlocked)
///   2. Device is not jailbroken (required — jailbroken iOS bypasses Keychain & sandbox protections)
///
/// Call `DeviceSecurityService.shared.evaluate()` at app launch.
/// If the device fails either check, present the returned `SecurityViolation` to block access.
final class DeviceSecurityService: @unchecked Sendable {

    static let shared = DeviceSecurityService()
    private init() {}

    // MARK: - Public API

    enum SecurityViolation: LocalizedError {
        case noPasscode
        case jailbroken

        var errorDescription: String? {
            switch self {
            case .noPasscode:
                return "Device Passcode Required"
            case .jailbroken:
                return "Unsupported Device"
            }
        }

        var recoverySuggestion: String {
            switch self {
            case .noPasscode:
                return "Milton Nation requires a device passcode, Face ID, or Touch ID to protect your health information. Please enable a passcode in Settings → Face ID & Passcode, then relaunch the app."
            case .jailbroken:
                return "Milton Nation cannot run on a modified device. The security protections required for health data are not available on jailbroken iOS devices."
            }
        }
    }

    /// Returns the first `SecurityViolation` found, or `nil` if the device is secure.
    func evaluate() -> SecurityViolation? {
        if isJailbroken() { return .jailbroken }
        if !hasPasscode()  { return .noPasscode }
        return nil
    }

    // MARK: - Passcode Check

    private func hasPasscode() -> Bool {
        #if targetEnvironment(simulator)
        // Simulators are sandboxed dev environments — no passcode hardware exists.
        // Blocking the MainActor with LAContext here would freeze the login screen.
        return true
        #else
        // LAContext.canEvaluatePolicy returns true if the device has any lock
        // (passcode, Face ID, Touch ID). It returns false if the device has no lock at all.
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        #endif
    }

    // MARK: - Jailbreak Detection

    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false   // Simulators are never jailbroken
        #else
        // Check 1: Common jailbreak file paths
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) { return true }
        }

        // Check 2: Can we write outside our sandbox?
        let testPath = "/private/jailbreak_test_\(UUID().uuidString).txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath) // best-effort cleanup; file existing confirms jailbreak
            return true   // Wrote outside sandbox — jailbroken
        } catch {
            // Expected: permission denied on stock iOS
        }

        return false
        #endif
    }
}
