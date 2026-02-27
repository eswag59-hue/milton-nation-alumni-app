import SwiftUI

@main
struct Milton_Nation_Alumni_AppApp: App {
    @State private var appViewModel: AppViewModel
    @State private var adminViewModel = AdminViewModel()
    @State private var sessionManager = SessionManager()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var isRestoringSession = false
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Service switching: use real Supabase services when configured,
        // otherwise fall back to mock services for development/testing.
        let authService: AuthServiceProtocol
        let dataService: DataServiceProtocol

        #if DEBUG
        if SupabaseConfig.isConfigured {
            authService = SupabaseAuthService()
            dataService = SupabaseDataService()
            AuditLogger.shared.persistToSupabase = true
        } else {
            authService = MockAuthService()
            dataService = MockDataService()
        }
        #else
        authService = SupabaseAuthService()
        dataService = SupabaseDataService()
        AuditLogger.shared.persistToSupabase = true
        #endif

        _appViewModel = State(initialValue: AppViewModel(
            authService: authService,
            dataService: dataService
        ))
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

                                Text("Milton Alumni")
                                    .font(.title3.bold())
                                    .foregroundStyle(AppTheme.textPrimary)

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
                // Attempt to restore existing session on app launch
                await restoreSessionIfNeeded()
                // Refresh remote moderation keywords in the background (non-blocking)
                Task { await RemoteModerationKeywordsService.shared.refreshIfNeeded() }
            }
            .onChange(of: scenePhase) {
                sessionManager.handleScenePhase(scenePhase)

                // Sync any pending audit entries when app comes to foreground
                if scenePhase == .active {
                    AuditLogger.shared.syncPendingEntries()
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

        if let user = await supabaseAuth.restoreSession() {
            appViewModel.login(user: user)
        } else {
            // Token was invalid — clean up
            KeychainService.delete(key: .authToken)
        }
    }
}
