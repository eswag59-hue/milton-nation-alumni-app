import SwiftUI
import LocalAuthentication
import UIKit
import UserNotifications

extension Notification.Name {
    /// Posted when a care-team push is tapped — the UI opens the alerts inbox.
    static let openCareTeamAlerts = Notification.Name("openCareTeamAlerts")
}

/// Survives a cold launch: a care-team push tapped while the app is dead sets
/// this before the UI (or the session) exists. ContentView consumes it once the
/// user is authenticated, so the tap is never dropped or fired over the login
/// screen.
@MainActor
enum DeepLinkRouter {
    static var pendingCareTeamAlerts = false
}

/// SwiftUI apps only receive the APNs device-token callbacks through a UIKit
/// app delegate. Without this, `registerForRemoteNotifications()` fires but the
/// token is never delivered — so no token is ever stored and push never works.
///
/// It is also the `UNUserNotificationCenterDelegate`. Without setting that
/// delegate + implementing `willPresent`, iOS SILENTLY SUPPRESSES notification
/// banners whenever the app is in the foreground — so a push that APNs accepted
/// (status 200) shows nothing on screen, which looks exactly like "push is
/// broken." Care-team and crisis alerts must be visible even with the app open.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationService.shared.didFailToRegisterForRemoteNotifications(withError: error)
    }

    /// Show the banner (+ sound + badge) even when the app is in the foreground.
    /// This is what makes a delivered push actually appear on screen while the
    /// user is in the app — the missing piece that made push look dead.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// Tapping a notification brings the app forward; routing to a specific
    /// screen can be layered on later. For now, just don't drop the tap.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Route a tapped care-team alert to the in-app alerts inbox. Set the
        // pending flag (for cold launch, before ContentView/session exist) AND
        // post now (for a warm tap). ContentView consumes it only once the user
        // is authenticated staff.
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String, type == "care_team_alert" {
            DeepLinkRouter.pendingCareTeamAlerts = true
            NotificationCenter.default.post(name: .openCareTeamAlerts, object: nil)
        }
        completionHandler()
    }
}

@main
struct Milton_Nation_Alumni_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appViewModel: AppViewModel
    @State private var adminViewModel: AdminViewModel
    @State private var sessionManager = SessionManager()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var isRestoringSession = false
    @State private var deviceSecurityViolation: DeviceSecurityService.SecurityViolation?
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    /// When on, the app requires Face ID / passcode to re-open after backgrounding.
    @AppStorage("app_lock_enabled") private var appLockEnabled = false
    @State private var isAppLocked = false
    @Environment(\.scenePhase) private var scenePhase

    /// Prompt Face ID / device passcode to unlock. On success clears the lock;
    /// failure keeps the lock screen so the user can retry or sign out.
    private func unlockWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics/passcode available — don't trap the user.
            isAppLocked = false
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: "Unlock Milton Nation") { success, _ in
            Task { @MainActor in if success { isAppLocked = false } }
        }
    }

    init() {
        // Service switching: use real Supabase services when configured,
        // otherwise fall back to mock services for development/testing.
        let authService: AuthServiceProtocol
        let dataService: DataServiceProtocol

        #if DEBUG
        // DEBUG (simulator + real device): always use mock services.
        // Login with any email that isn't admin@milton.com or super@milton.com,
        // any password, and any 6-digit OTP code.
        // The real Supabase auth stack is only active in Release (App Store) builds.
        authService = MockAuthService()
        dataService = MockDataService()
        #else
        // Release build: always Supabase.
        authService = SupabaseAuthService()
        dataService = SupabaseDataService()
        AuditLogger.shared.persistToSupabase = true
        #endif

        // Install crash handler as early as possible — before any other async work.
        CrashReportingService.shared.install()

        _appViewModel = State(initialValue: AppViewModel(
            authService: authService,
            dataService: dataService
        ))
        // Wire the SAME dataService into AdminViewModel — without this, admins
        // in Release saw mock alumni rosters because AdminViewModel's default
        // arg is MockDataService().
        _adminViewModel = State(initialValue: AdminViewModel(dataService: dataService))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(appViewModel: appViewModel)
                    .environment(appViewModel)
                    .environment(adminViewModel)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        OfflineBanner(isConnected: networkMonitor.isConnected)
                            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
                    }

                // HIPAA: Background blur overlay to protect PHI
                if sessionManager.showBackgroundBlur && appViewModel.isAuthenticated {
                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("App Protected")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                }

                // App Lock — Face ID gate on re-open when enabled in Settings.
                if isAppLocked && appViewModel.isAuthenticated {
                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 20) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppTheme.accent)
                                Text("Milton Nation is locked")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Button {
                                    unlockWithBiometrics()
                                } label: {
                                    Text("Unlock with Face ID")
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 24).padding(.vertical, 12)
                                        .background(AppTheme.accent)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                                Button("Sign Out") {
                                    isAppLocked = false
                                    appViewModel.logout()
                                }
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                }

                // Session restoration / launch screen
                if isRestoringSession {
                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 24) {
                                MiltonLogoView(size: .large)

                                ProgressView()
                                    .controlSize(.regular)
                                    .tint(AppTheme.accent)

                                Text("Signing you in...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                }
            }
            .task {
                // HIPAA: on a FRESH install, clear any auth material a prior
                // install left behind. UserDefaults is wiped on app deletion but
                // the Keychain (and the Supabase SDK's persisted session) are
                // NOT — so without this a reinstall on a shared/resold device
                // could silently restore the previous user's PHI-bearing session.
                await purgeStaleSessionIfFreshInstall()

                // HIPAA: Verify device security before any data access.
                // IMPORTANT: Run on a background thread via Task.detached — LAContext.canEvaluatePolicy
                // can stall briefly (especially on simulator / cold boot). Calling it synchronously
                // on the MainActor would block SwiftUI's render loop and freeze the login screen.
                let securityService = DeviceSecurityService.shared
                let violation = await Task.detached(priority: .userInitiated) {
                    await securityService.evaluate()
                }.value
                deviceSecurityViolation = violation   // back on MainActor — safe to write @State
                guard violation == nil else { return }

                // Attempt to restore existing session on app launch
                await restoreSessionIfNeeded()
                // Upload crash report and refresh keywords in background — never block login screen
                Task { await CrashReportingService.shared.uploadPendingReportIfNeeded() }
                Task { await RemoteModerationKeywordsService.shared.refreshIfNeeded() }
            }
            .alert(
                deviceSecurityViolation?.errorDescription ?? "Security Check Failed",
                isPresented: Binding(
                    get: { deviceSecurityViolation != nil },
                    set: { _ in /* non-dismissible — user must fix device settings */ }
                )
            ) {
                // No dismiss — user must fix device settings and relaunch
                Button("OK") {
                    // Tapping OK does nothing; the alert is controlled by deviceSecurityViolation
                    // which only clears if the violation is resolved on next app launch.
                }
            } message: {
                Text(deviceSecurityViolation?.recoverySuggestion ?? "")
            }
            .interactiveDismissDisabled(deviceSecurityViolation != nil)
            .onChange(of: scenePhase) {
                sessionManager.handleScenePhase(scenePhase)

                // App Lock: arm on background, prompt Face ID on return.
                if scenePhase == .background, appLockEnabled, appViewModel.isAuthenticated {
                    isAppLocked = true
                }
                if scenePhase == .active, isAppLocked, appViewModel.isAuthenticated {
                    unlockWithBiometrics()
                }

                if scenePhase == .active {
                    // Sync any pending audit entries when app comes to foreground
                    AuditLogger.shared.syncPendingEntries()

                    // Re-establish any Realtime WebSocket subscriptions that may have
                    // dropped while the app was backgrounded. The notification triggers
                    // each ViewModel to call its subscribe…() method again.
                    if appViewModel.isAuthenticated {
                        RealtimeService.shared.reconnectIfNeeded()
                    }
                }

                // Flush buffered analytics on background so no events are lost if app is killed
                if scenePhase == .background {
                    AnalyticsService.shared.flush()
                }
            }
            .onChange(of: sessionManager.isSessionExpired) {
                if sessionManager.isSessionExpired && appViewModel.isAuthenticated {
                    appViewModel.logout()
                    sessionManager.stopMonitoring()
                }
            }
            .onChange(of: appViewModel.isAuthenticated) {
                if appViewModel.isAuthenticated {
                    sessionManager.startMonitoring()
                } else {
                    sessionManager.stopMonitoring()
                }
            }
            .alert("Screenshot Detected", isPresented: $sessionManager.showScreenshotAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This app contains protected health information. Please be mindful of screenshots.")
            }
            .preferredColorScheme(appearanceMode.colorScheme)
            .screenshotProtected()
        }
    }

    // MARK: - Fresh-install session hygiene (HIPAA)

    /// On the first launch after a fresh install, purge any leftover auth
    /// material. UserDefaults is cleared when an app is deleted, but the
    /// Keychain and the Supabase SDK's stored session survive deletion — so a
    /// reinstall could otherwise auto-restore the prior user's session on a
    /// shared or resold device. Uses a UserDefaults marker (itself cleared on
    /// delete) to detect the fresh install.
    private func purgeStaleSessionIfFreshInstall() async {
        let marker = "com.miltonrecovery.hasLaunchedBefore"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: marker) else { return }
        defaults.set(true, forKey: marker)

        KeychainService.delete(key: .authToken)
        KeychainService.delete(key: .mfaCompleted)
        // Clear the SDK's own persisted session (local only — no network).
        if let supabaseAuth = appViewModel.authService as? SupabaseAuthService {
            await supabaseAuth.clearLocalSession()
        }
    }

    // MARK: - Session Restoration

    private func restoreSessionIfNeeded() async {
        // Only attempt restore if we have a Supabase auth service
        guard let supabaseAuth = appViewModel.authService as? SupabaseAuthService else {
            return
        }

        // Only restore if not already authenticated, there's a stored token,
        // AND the SMS second factor was completed on a prior session. Without
        // the mfaCompleted gate, a user who force-quits at the OTP screen
        // (password accepted, Supabase session already live, OTP not yet
        // entered) would be silently auto-logged-in on relaunch — skipping the
        // second factor entirely. mfaCompleted is only written after a
        // successful OTP verification, so it's the correct gate.
        guard !appViewModel.isAuthenticated,
              KeychainService.loadString(key: .authToken) != nil,
              KeychainService.loadString(key: .mfaCompleted) == "true" else {
            return
        }

        isRestoringSession = true
        defer { isRestoringSession = false }

        // Race session restore against a 5-second timeout.
        // Without this, a stale Keychain token + slow/no network causes
        // the "Signing you in…" overlay to block the login screen for up to
        // 75 seconds (the iOS TCP timeout) — making the app appear frozen.
        let user: User? = await withTaskGroup(of: User?.self) { group in
            group.addTask { await supabaseAuth.restoreSession() }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return nil   // timeout sentinel
            }
            // Take whichever result arrives first, cancel the other.
            for await result in group {
                group.cancelAll()
                return result
            }
            return nil
        }

        if let user {
            appViewModel.login(user: user)
        }
        // else: restore returned nil. Do NOT delete credentials here.
        // `restoreSession()` already purges the token on a *definitive* auth
        // failure (expired/invalid/401). A nil here is otherwise a transient
        // network error or the 5-second timeout — deleting on those forces a
        // full email+password+OTP re-login on flaky wifi AND removes the
        // "Sign in with Face ID" affordance (gated on .mfaCompleted). Keeping
        // the token lets the next launch (or Face ID) retry cleanly.
    }
}
