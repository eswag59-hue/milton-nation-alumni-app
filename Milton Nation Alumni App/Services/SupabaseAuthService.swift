import Foundation
import Supabase

// MARK: - Edge Function Response Types

private struct SMSOTPResponse: Decodable {
    let success: Bool?
    let phone: String?
    let error: String?
}

private struct VerifyOTPResponse: Decodable {
    let verified: Bool?
    let error: String?
}

nonisolated private struct WelcomeEmailParams: Encodable, Sendable {
    // NOTE: name is intentionally omitted — Resend has no HIPAA BAA.
    // Never add PHI (name, phone, diagnosis, etc.) to this struct.
    let to: String
}

nonisolated private struct AdminRegistrationNotifParams: Encodable, Sendable {
    let target: String
    let roles: [String]
    let title: String
    let body: String
    let data: [String: String]
}

/// Production authentication service using Supabase Auth.
///
/// Implements `AuthServiceProtocol` so every ViewModel that currently works
/// with `MockAuthService` automatically works with this implementation.
final class SupabaseAuthService: AuthServiceProtocol {

    private let client = SupabaseConfig.client
    private var cachedUser: User?

    // MARK: - Login

    func login(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        // Fetch the full profile from the profiles table
        let profile: User = try await client.from("profiles")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        // Access control: admin/superAdmin must have .active status
        if profile.role == .admin || profile.role.isSuperAdmin {
            guard profile.status == .active else {
                try await client.auth.signOut()
                throw NSError(
                    domain: "auth",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "This admin account has not been approved or is inactive."]
                )
            }
        }

        // Update last login
        _ = try? await client.from("profiles")
            .update(["last_login": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: session.user.id.uuidString)
            .execute()

        // Store session token in Keychain for persistence
        if let tokenData = session.accessToken.data(using: .utf8) {
            KeychainService.save(key: .authToken, data: tokenData)
        }

        cachedUser = profile
        return profile
    }

    // MARK: - Send SMS OTP

    func sendSMSOTP(userId: UUID) async throws {
        // Call the send-sms-otp Edge Function
        // The JWT is automatically included from the current session
        let response: SMSOTPResponse = try await client.functions.invoke(
            "send-sms-otp",
            options: .init(method: .post)
        )

        // Check for errors in the response
        if let error = response.error {
            throw NSError(
                domain: "auth",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: error]
            )
        }
    }

    // MARK: - MFA Verification (SMS OTP)

    func verifyMFA(userId: UUID, code: String) async throws -> User {
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw NSError(
                domain: "auth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"]
            )
        }

        // Call the verify-sms-otp Edge Function
        let response: VerifyOTPResponse = try await client.functions.invoke(
            "verify-sms-otp",
            options: .init(
                method: .post,
                body: ["code": code]
            )
        )

        if response.verified == true {
            // Mark MFA as completed in Keychain
            KeychainService.save(key: .mfaCompleted, string: "true")

            guard let user = cachedUser else {
                throw NSError(
                    domain: "auth",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "MFA session expired. Please log in again."]
                )
            }
            return user
        } else {
            let errorMsg = response.error ?? "Verification failed. Please try again."
            throw NSError(
                domain: "auth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
        }
    }

    // MARK: - Logout

    func logout() async throws {
        // Always clear local state even if signOut throws (network offline, etc.)
        defer {
            KeychainService.delete(key: .authToken)
            KeychainService.delete(key: .mfaCompleted)
            cachedUser = nil
        }
        try await client.auth.signOut()
    }

    // MARK: - Register

    func register(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        sobrietyDate: Date,
        dischargeDate: Date,
        recoveryProgram: String,
        facility: Facility?
    ) async throws -> User {
        // Create auth user in Supabase Auth
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": .string(fullName),
                "phone": .string(phone)
            ]
        )

        // authResponse.user is non-optional in Supabase SDK v2
        let authUser = authResponse.user

        // The trigger `handle_new_user` in schema.sql auto-creates the profile row.
        // But we need to update the additional fields the trigger doesn't set.
        let dateFormatter = ISO8601DateFormatter()

        var profileUpdate: [String: String] = [
            "phone": phone,
            "full_name": fullName,
            "username": fullName.lowercased().replacingOccurrences(of: " ", with: "_"),
            "sobriety_date": dateFormatter.string(from: sobrietyDate),
            "discharge_date": dateFormatter.string(from: dischargeDate),
            "recovery_program": recoveryProgram,
        ]
        if let facility { profileUpdate["facility"] = facility.rawValue }

        try await client.from("profiles")
            .update(profileUpdate)
            .eq("id", value: authUser.id.uuidString)
            .execute()

        // Fetch the complete profile
        let profile: User = try await client.from("profiles")
            .select()
            .eq("id", value: authUser.id.uuidString)
            .single()
            .execute()
            .value

        cachedUser = profile

        // Fire welcome email + admin push notification — non-blocking, never fail registration
        let capturedEmail = email
        let capturedName = fullName
        let capturedId = authUser.id.uuidString
        let capturedFacility = facility?.displayName ?? "Unknown"
        Task {
            _ = try? await client.functions.invoke(
                "send-welcome-email",
                options: .init(method: .post, body: WelcomeEmailParams(to: capturedEmail))
            )
            _ = try? await client.functions.invoke(
                "send-push-notification",
                options: .init(method: .post, body: AdminRegistrationNotifParams(
                    target: "role",
                    roles: ["admin", "super_admin"],
                    title: "New Member Request (\(capturedFacility))",
                    body: "\(capturedName) has applied to join the \(capturedFacility) community.",
                    data: ["type": "new_registration", "userId": capturedId, "facility": facility?.rawValue ?? ""]
                ))
            )
        }

        return profile
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Get Current User (Session Restore)

    func getCurrentUser() -> User? {
        // First check cache
        if let cached = cachedUser { return cached }

        // Check if we have a stored token
        guard KeychainService.loadString(key: .authToken) != nil else {
            return nil
        }

        // Attempt to restore session asynchronously
        // This is synchronous per protocol, so we start a fire-and-forget restore.
        // The caller should also call restoreSessionAsync() on app launch.
        return nil
    }

    // MARK: - Async Session Restoration

    /// Call this on app launch to restore an existing session from Supabase.
    /// If the JWT is still valid (or can be refreshed), sets `cachedUser`.
    func restoreSession() async -> User? {
        // Skip the restore attempt entirely if no token is stored locally.
        // This avoids a spurious Supabase network call on first launch.
        guard KeychainService.loadString(key: .authToken) != nil else { return nil }

        do {
            // Supabase SDK v2 automatically refreshes the access token if the
            // refresh token is still valid, so this covers the "token expired" case.
            let session = try await client.auth.session
            let profile: User = try await client.from("profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            cachedUser = profile
            return profile
        } catch {
            // Only purge stored credentials on definitive authentication failures.
            // Network errors are transient — preserving the token allows the user
            // to stay logged in once connectivity is restored.
            let description = error.localizedDescription.lowercased()
            let isDefinitiveAuthFailure =
                description.contains("session") ||
                description.contains("expired") ||
                description.contains("unauthorized") ||
                description.contains("invalid") ||
                (error as NSError).code == 401

            if isDefinitiveAuthFailure {
                KeychainService.delete(key: .authToken)
                KeychainService.delete(key: .mfaCompleted)
                cachedUser = nil
            }
            return nil
        }
    }
}
