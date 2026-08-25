import SwiftUI
import UIKit

extension View {
    /// Protects PHI from screen recording, AirPlay mirroring, and QuickTime
    /// capture by overlaying a black privacy screen whenever `UIScreen.isCaptured`
    /// is true.
    ///
    /// **Why not the UITextField-wrapping technique?**
    /// Embedding the entire app inside a UITextField's private secure container
    /// (the older approach) wraps every SwiftUI view inside an extra
    /// UIViewController + UIHostingController layer. That breaks UIKit's
    /// responder chain, prevents SwiftUI TextFields from becoming first
    /// responder, and silently eats all touch events — making the whole app
    /// appear frozen. The private UITextField subview structure also changed in
    /// iOS 17, making that technique unreliable.
    ///
    /// **This implementation** attaches a standard SwiftUI `.overlay` and
    /// listens for `UIScreen.capturedDidChangeNotification`.  No UIKit view
    /// wrapping, no responder-chain interference, works on simulator and device.
    func screenshotProtected() -> some View {
        modifier(ScreenshotProtectionModifier())
    }
}

// MARK: - Modifier

private struct ScreenshotProtectionModifier: ViewModifier {

    @State private var isBeingCaptured = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isBeingCaptured {
                    captureBlocker
                }
            }
            // Set initial state synchronously so the overlay is ready before
            // the first frame is drawn (e.g. if a recording is already active).
            .onAppear {
                isBeingCaptured = Self.isCaptured
            }
            // React to recording / mirroring starting or stopping.
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIScreen.capturedDidChangeNotification
                )
            ) { notification in
                if MarketingCapture.isEnabled {
                    isBeingCaptured = false
                } else if let screen = notification.object as? UIScreen {
                    isBeingCaptured = screen.isCaptured
                } else {
                    isBeingCaptured = Self.isCaptured
                }
            }
    }

    /// iOS 16+ deprecated `UIScreen.screens`; read `isCaptured` via the
    /// connected scene's window instead.
    ///
    /// Reports `false` while a PHI-free demo account is signed in, so marketing
    /// can record the real app. See `MarketingCapture` — every real member is
    /// still fully protected.
    private static var isCaptured: Bool {
        guard !MarketingCapture.isEnabled else { return false }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
            .isCaptured ?? false
    }

    /// Full-screen black overlay shown during screen recording / mirroring.
    private var captureBlocker: some View {
        Color.black
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)

                    Text("Screen Recording Blocked")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("Milton Nation protects your health\ninformation from screen capture.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: isBeingCaptured)
    }
}
