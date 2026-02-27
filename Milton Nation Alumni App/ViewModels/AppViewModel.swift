import SwiftUI

@Observable
final class AppViewModel {
    var currentUser: User?
    var isAuthenticated = false
    var selectedTab: AppTab = .home

    // Post-login modals
    var showSobrietyCheck = false

    // Struggle Mode
    var isStrugglingMode = false

    // Admin: View as User mode
    var isViewingAsUser = false

    let authService: AuthServiceProtocol
    let dataService: DataServiceProtocol

    init(authService: AuthServiceProtocol = MockAuthService(),
         dataService: DataServiceProtocol = MockDataService()) {
        self.authService = authService
        self.dataService = dataService
    }

    // MARK: - Auth

    func login(user: User) {
        currentUser = user
        isAuthenticated = true
        selectedTab = .home
        showSobrietyCheck = true
        awardDailyLoginPoints()
        AuditLogger.shared.log(.login, userId: user.id, detail: "Role: \(user.role.rawValue)")

        // Register device for push notifications
        PushNotificationService.shared.registerDeviceToken(userId: user.id)

        // Request push notification permission on first login
        requestNotificationPermissionIfNeeded()

        // Cache user profile for offline access
        OfflineCacheService.shared.cacheUserProfile(user)

        // If pending, subscribe to profile status changes so we can fire a local
        // notification the moment an admin approves the account (works on simulator too)
        if user.status == .pending {
            startProfileApprovalMonitoring(userId: user.id)
        }

        // If admin/super_admin, subscribe to new pending user registrations
        // for real-time local notifications (simulator fallback — real devices use APNs)
        if user.role.isAdmin || user.role.isSuperAdmin {
            RealtimeService.shared.subscribeToPendingUsers { newUser in
                PushNotificationService.shared.scheduleLocalNotification(
                    title: "New Member Request",
                    body: "\(newUser.fullName) has applied to join Milton Nation.",
                    userInfo: ["type": "new_registration", "userId": newUser.id.uuidString]
                )
            }
        }
    }

    // MARK: - Profile Approval Monitoring

    private func startProfileApprovalMonitoring(userId: UUID) {
        RealtimeService.shared.subscribeToUserProfile(userId: userId) { [weak self] newStatus in
            guard let self else { return }
            if newStatus == .active {
                // Local notification — fires on simulator AND real device
                // (real device also gets APNs push from the edge function)
                PushNotificationService.shared.scheduleLocalNotification(
                    title: "You're Approved! 🎉",
                    body: "Your Milton Nation account is now active. Welcome to the community!",
                    userInfo: ["type": "account_approved"]
                )
                self.currentUser?.status = .active
            }
        }
    }

    // MARK: - Push Notification Permission

    private static let hasRequestedNotificationKey = "has_requested_notification_permission"

    private func requestNotificationPermissionIfNeeded() {
        let hasRequested = UserDefaults.standard.bool(forKey: Self.hasRequestedNotificationKey)
        if !hasRequested {
            // Small delay so the login UI settles before the system dialog appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                PushNotificationService.shared.requestPermission()
                UserDefaults.standard.set(true, forKey: Self.hasRequestedNotificationKey)
            }
        }
    }

    func logout() {
        let userId = currentUser?.id
        Task {
            try? await authService.logout()
            await MainActor.run {
                AuditLogger.shared.log(.logout, userId: userId)
                KeychainService.delete(key: .authToken)

                // Disconnect all Realtime subscriptions
                RealtimeService.shared.disconnectAll()

                // Unregister push notification device token
                PushNotificationService.shared.unregisterDeviceToken()

                currentUser = nil
                isAuthenticated = false
                isStrugglingMode = false
                isViewingAsUser = false
                selectedTab = .home
                showSobrietyCheck = false
            }
        }
    }

    // MARK: - Delete Account

    func deleteAccount() {
        guard let user = currentUser else { return }
        Task {
            do {
                // Set status to deactivated (30-day grace period before permanent deletion)
                var deactivatedUser = user
                deactivatedUser.status = .deactivated
                _ = try await dataService.updateProfile(user: deactivatedUser)
                AuditLogger.shared.log(.logout, userId: user.id, detail: "Account deactivated — pending deletion")
            } catch {
                #if DEBUG
                print("[AppViewModel] Failed to deactivate account: \(error.localizedDescription)")
                #endif
            }

            // Log out regardless of deactivation result
            try? await authService.logout()
            await MainActor.run {
                KeychainService.delete(key: .authToken)
                RealtimeService.shared.disconnectAll()
                PushNotificationService.shared.unregisterDeviceToken()
                currentUser = nil
                isAuthenticated = false
                isStrugglingMode = false
                isViewingAsUser = false
                selectedTab = .home
                showSobrietyCheck = false
            }
        }
    }

    // MARK: - Sobriety

    func resetSobrietyDate(to date: Date = Date()) {
        guard currentUser != nil else { return }
        currentUser?.sobrietyDate = date
        Task {
            if let user = currentUser {
                _ = try? await dataService.updateProfile(user: user)
            }
        }
    }

    // MARK: - Struggle Mode

    func enterStrugglingMode() {
        isStrugglingMode = true
        selectedTab = .chat
    }

    func exitStrugglingMode() {
        isStrugglingMode = false
    }

    // MARK: - Points

    private func awardDailyLoginPoints() {
        // Only award points once per calendar day
        if let lastAwarded = currentUser?.lastPointsAwarded,
           Calendar.current.isDateInToday(lastAwarded) {
            return // Already awarded today
        }

        Task {
            if let newTotal = try? await dataService.awardPoints(action: .dailyLogin) {
                await MainActor.run {
                    currentUser?.totalPoints = newTotal
                    currentUser?.lastPointsAwarded = Date()
                }
            }
        }
    }
}

enum AppTab: String, CaseIterable {
    case home = "Home"
    case community = "Community"
    case meetings = "Meetings"
    case chat = "Chat"
    case profile = "Profile"

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .community: return "person.2.fill"
        case .meetings: return "calendar"
        case .chat: return "message.fill"
        case .profile: return "person.circle.fill"
        }
    }
}
