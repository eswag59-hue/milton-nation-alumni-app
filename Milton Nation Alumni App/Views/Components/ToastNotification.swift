import SwiftUI

/// A reusable animated toast overlay that slides in from the top and auto-dismisses.
struct ToastNotification: View {
    let icon: String
    let message: String
    @Binding var isShowing: Bool
    var duration: Double = 3.0

    var body: some View {
        if isShowing {
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowing = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
        }
    }
}
