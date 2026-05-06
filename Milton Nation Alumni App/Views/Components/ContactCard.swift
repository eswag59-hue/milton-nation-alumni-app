import SwiftUI

struct ContactCard: View {
    let name: String
    let role: String
    var photoURL: String? = nil
    var onMessage: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            // Avatar + Info
            HStack(spacing: 12) {
                // Render the actual staff photo when available, falling back
                // to the silhouette placeholder when missing or still loading.
                if let urlString = photoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                        case .failure, .empty:
                            Circle()
                                .fill(AppTheme.accent.opacity(0.2))
                                .frame(width: 52, height: 52)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.accent)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.2))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)
                        }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(role)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .foregroundStyle(AppTheme.accent)
                        .background(AppTheme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()

                // Blue message icon — tapping navigates to the same chat thread
                Image(systemName: "message.circle.fill")
                    .font(.title)
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding()
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(role)")
        .accessibilityHint("Double tap to message")
    }
}
