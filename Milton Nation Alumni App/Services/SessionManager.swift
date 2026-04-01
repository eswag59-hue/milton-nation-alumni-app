import SwiftUI

@Observable
final class SessionManager {
    var isSessionExpired = false
    var showBackgroundBlur = false
    var showScreenshotAlert = false

    private var idleTimer: Timer?
    private let timeoutInterval: TimeInterval = 30 * 60 // 30 minutes

    private var screenshotObserver: Any?

    // MARK: - Session Timeout

    func startMonitoring() {
        resetIdleTimer()
        observeScreenshots()
    }

    func stopMonitoring() {
        idleTimer?.invalidate()
        idleTimer = nil
        removeScreenshotObserver()
        showBackgroundBlur = false
    }

    func resetIdleTimer() {
        idleTimer?.invalidate()
        isSessionExpired = false
        idleTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { @Sendable [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isSessionExpired = true
            }
        }
    }

    func recordActivity() {
        resetIdleTimer()
    }

    // MARK: - Scene Phase Handling

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            showBackgroundBlur = false
            resetIdleTimer()
        case .inactive, .background:
            showBackgroundBlur = true
        @unknown default:
            break
        }
    }

    // MARK: - Screenshot Detection

    private func observeScreenshots() {
        screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showScreenshotAlert = true
        }
    }

    private func removeScreenshotObserver() {
        if let observer = screenshotObserver {
            NotificationCenter.default.removeObserver(observer)
            screenshotObserver = nil
        }
    }
}
