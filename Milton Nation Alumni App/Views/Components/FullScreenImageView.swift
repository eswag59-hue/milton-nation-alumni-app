import SwiftUI

/// Wrapper so a URL can drive `.fullScreenCover(item:)` (which needs Identifiable).
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

/// A tap-to-dismiss, pinch-to-zoom fullscreen image viewer, presented over a
/// black background. Used when a member taps a post's image to see it large.
struct FullScreenImageView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(lastScale * value, 1), 5)
                                }
                                .onEnded { _ in lastScale = scale }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation { scale = scale > 1 ? 1 : 2; lastScale = scale }
                        }
                case .failure:
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("Image unavailable").font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                case .empty:
                    ProgressView().tint(.white)
                @unknown default:
                    EmptyView()
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        // Single tap anywhere (when not zoomed) closes the viewer.
        .contentShape(Rectangle())
        .onTapGesture {
            if scale <= 1 { dismiss() }
        }
    }
}
