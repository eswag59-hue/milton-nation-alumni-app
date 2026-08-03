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

    /// Re-register for remote notifications on every login **if permission was
    /// already granted**. Without this, a returning user (who granted permission
    /// on a past launch, so `requestPermission` is skipped) never calls
    /// `registerForRemoteNotifications` again — so their APNs token is never
    /// re-fetched or re-synced, and `device_tokens` can go stale or stay empty.
    /// Apple recommends registering on every launch anyway; the token is cached
    /// so this is cheap and returns quickly via the AppDelegate callback.
    func refreshRegistrationIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

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
                    ), onConflict: "user_id,token")   // else it conflicts on the
                    // PK (id), generates a new id, and violates UNIQUE(user_id,
                    // token) on every re-registration — noisy 23505 errors.
                    .execute()
                #if DEBUG
                print("[PushNotification] ✅ Token synced to Supabase")
                #endif
            } catch {
                CrashReportingService.shared.recordError(error, context: "PushNotificationService.syncTokenToBackend")
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

    // MARK: - Notification Preferences

    /// Notification category used to gate delivery against user preferences.
    enum NotificationType {
        case communityPost
        case chat
        case meeting
        case milestone
        case general   // always delivered (crisis alerts, system messages)
    }

    /// Returns true if the user has enabled notifications for this category.
    /// Reads from the same UserDefaults keys written by SettingsScreen.
    func isEnabled(_ type: NotificationType) -> Bool {
        switch type {
        case .communityPost: return UserDefaults.standard.object(forKey: "notifications_community") as? Bool ?? true
        case .chat:          return UserDefaults.standard.object(forKey: "notifications_chat") as? Bool ?? true
        case .meeting:       return UserDefaults.standard.object(forKey: "notifications_meetings") as? Bool ?? true
        case .milestone:     return UserDefaults.standard.object(forKey: "notifications_milestones") as? Bool ?? true
        case .general:       return true
        }
    }

    /// Sync notification preferences to the device_tokens record in Supabase
    /// so the backend can filter push delivery server-side.
    func syncPreferences() {
        guard SupabaseConfig.isConfigured, let userId = currentUserId, let token = deviceToken else { return }
        let prefs: [String: Bool] = [
            "community": isEnabled(.communityPost),
            "chat":      isEnabled(.chat),
            "meetings":  isEnabled(.meeting),
            "milestones": isEnabled(.milestone)
        ]
        Task {
            _ = try? await SupabaseConfig.client.from("device_tokens")
                .update(["notification_preferences": prefs])
                .eq("user_id", value: userId.uuidString)
                .eq("token", value: token)
                .execute()
        }
    }

    // MARK: - Local Notifications (Fallback)

    /// Schedule a local notification, respecting the user's per-category preferences.
    func scheduleLocalNotification(
        title: String,
        body: String,
        type: NotificationType = .general,
        userInfo: [String: Any] = [:]
    ) {
        guard isEnabled(type) else { return }

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
