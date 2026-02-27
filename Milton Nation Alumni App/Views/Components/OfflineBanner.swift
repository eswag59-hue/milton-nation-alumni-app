import SwiftUI

/// A slim banner that slides in from the top when the device loses network connectivity.
/// Automatically hides when connectivity is restored.
///
/// Usage: Place at the top of a ZStack or overlay on the main content view.
struct OfflineBanner: View {
    var isConnected: Bool

    var body: some View {
        if !isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline.bold())
                Text("No Internet Connection")
                    .font(.subheadline.bold())
                Spacer()
                Text("Offline Mode")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.struggling.gradient)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
