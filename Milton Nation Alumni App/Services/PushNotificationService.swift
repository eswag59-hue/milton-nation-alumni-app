import Foundation
import UserNotifications
import UIKit
import Supabase

/// Manages push notification registration, permissions, and device token storage.
///
/// On app launch:
///   PushNotificationService.shared.requestPermission()
///
/// After login:
///   PushNotificationService.shared.registerDeviceToken(userId: user.id)
///
/// On logout:
///   PushNotificationService.shared.unregisterDeviceToken()
///
/// Note: Requires Apple Developer account with Push Notification capability enabled.
/// The actual sending of remote push notifications is handled server-side
/// (Supabase Edge Function → APNs).
final class PushNotificationService: NSObject, @unchecked Sendable {

    static let shared = PushNotificationService()

    /// The APNs device token, set after successful registration.
    private(set) var deviceToken: String?

    /// Current user ID for associating the token.
    private var currentUserId: UUID?

    private override init() {
        super.init()
    }

    // MARK: - Permission

    /// Request notification permission from the user.
    /// Call this early in the app lifecycle (e.g., after first login).
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error {
                #if DEBUG
                print("[PushNotification] ⚠️ Permission error: \(error.localizedDescription)")
                #endif
                return
            }

            if granted {
                #if DEBUG
                print("[PushNotification] ✅ Permission granted")
                #endif
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                #if DEBUG
                print("[PushNotification] ❌ Permission denied")
                #endif
            }
        }
    }

    // MARK: - Device Token

    /// Called from AppDelegate when APNs returns a device token.
    /// Stores the token and syncs it to Supabase if a user is logged in.
    func didRegisterForRemoteNotifications(withDeviceToken token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        #if DEBUG
        print("[PushNotification] 📱 Device token: \(tokenString)")
        #endif

        // If user is already logged in, sync token to backend
        if let userId = currentUserId {
            syncTokenToBackend(userId: userId, token: tokenString)
        }
    }

    /// Called from AppDelegate when registration fails.
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        #if DEBUG
        print("[PushNotification] ⚠️ Failed to register: \(error.localizedDescription)")
        #endif
    }

    // MARK: - User Association

    /// Associate the device token with a user after login.
    func registerDeviceToken(userId: UUID) {
        currentUserId = userId
        if let token = deviceToken {
            syncTokenToBackend(userId: userId, token: token)
        }
    }

    /// Disassociate the device token on logout.
    func unregisterDeviceToken() {
        guard let userId = currentUserId, let token = deviceToken else { return }
        removeTokenFromBackend(userId: userId, token: token)
        currentUserId = nil
    }

    // MARK: - Backend Sync

    /// Store the device token in Supabase for server-side push delivery.
    private func syncTokenToBackend(userId: UUID, token: String) {
        guard SupabaseConfig.isConfigured else { return }

        Task {
            do {
                try await SupabaseConfig.client.from("device_tokens")
                    .upsert(DeviceTokenParams(
                        userId: userId,
                        token: token,
                        platform: "ios",
                        updatedAt: ISO8601DateFormatter().string(from: Date())
                    ))
                    .execute()
                #if DEBUG
                print("[PushNotification] ✅ Token synced to Supabase")
                #endif
            } catch {
                #if DEBUG
                print("[PushNotification] ⚠️ Failed to sync token: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Remove the device token from Supabase on logout.
    private func removeTokenFromBackend(userId: UUID, token: String) {
        guard SupabaseConfig.isConfigured else { return }

        Task {
            do {
                try await SupabaseConfig.client.from("device_tokens")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("token", value: token)
                    .execute()
                #if DEBUG
                print("[PushNotification] ✅ Token removed from Supabase")
                #endif
            } catch {
                #if DEBUG
                print("[PushNotification] ⚠️ Failed to remove token: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Local Notifications (Fallback)

    /// Schedule a local notification (used when push isn't available or for
    /// immediate in-app events like comment notifications).
    func scheduleLocalNotification(
        title: String,
        body: String,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Device Token Params

nonisolated private struct DeviceTokenParams: Encodable, Sendable {
    let userId: UUID
    let token: String
    let platform: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case token
        case platform
        case updatedAt = "updated_at"
    }
}
