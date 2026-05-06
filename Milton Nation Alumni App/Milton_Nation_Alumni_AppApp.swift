import SwiftUI

@main
struct Milton_Nation_Alumni_AppApp: App {
    @State private var appViewModel: AppViewModel
    @State private var adminViewModel: AdminViewModel
    @State private var sessionManager = SessionManager()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var isRestoringSession = false
    @State private var deviceSecurityViolation: DeviceSecurityService.SecurityViolation?
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    @Environment(\.scenePhase) private var scenePhase

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

    // MARK: - Session Restoration

    private func restoreSessionIfNeeded() async {
        // Only attempt restore if we have a Supabase auth service
        guard let supabaseAuth = appViewModel.authService as? SupabaseAuthService else {
            return
        }

        // Only restore if not already authenticated and there's a stored token
        guard !appViewModel.isAuthenticated,
              KeychainService.loadString(key: .authToken) != nil else {
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
        } else {
            // Token was invalid or restore timed out — clear stale credentials
            // so the user is presented with a clean login screen.
            KeychainService.delete(key: .authToken)
            KeychainService.delete(key: .mfaCompleted)
        }
    }
}
