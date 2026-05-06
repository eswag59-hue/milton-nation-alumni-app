import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                switch message.messageType {
                case .text:
                    if let content = message.content {
                        Text(content)
                            .font(.body)
                            .foregroundStyle(isFromCurrentUser ? .white : AppTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isFromCurrentUser ? AppTheme.accent : AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                case .image:
                    VStack(spacing: 6) {
                        if let urlString = message.mediaURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                case .failure:
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.background)
                                        .frame(width: 200, height: 150)
                                        .overlay {
                                            VStack(spacing: 4) {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundStyle(AppTheme.textSecondary)
                                                Text("Image unavailable")
                                                    .font(.caption2)
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }
                                        }
                                case .empty:
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.background.opacity(0.5))
                                        .frame(width: 200, height: 150)
                                        .overlay { ProgressView() }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            // No URL yet (still uploading or no media stored)
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isFromCurrentUser ? AppTheme.accent.opacity(0.3) : AppTheme.background)
                                .frame(width: 200, height: 150)
                                .overlay {
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo.fill")
                                            .font(.title)
                                            .foregroundStyle(isFromCurrentUser ? .white.opacity(0.7) : AppTheme.textSecondary.opacity(0.5))
                                        Text("Photo")
                                            .font(.caption)
                                            .foregroundStyle(isFromCurrentUser ? .white.opacity(0.7) : AppTheme.textSecondary)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                case .voice:
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isFromCurrentUser ? .white : AppTheme.accent)
                        Image(systemName: "waveform")
                            .font(.body)
                            .foregroundStyle(isFromCurrentUser ? .white.opacity(0.7) : AppTheme.textSecondary)
                        Text(Self.formatVoiceDuration(message.voiceDuration))
                            .font(.caption)
                            .foregroundStyle(isFromCurrentUser ? .white.opacity(0.7) : AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? AppTheme.accent : AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                case .file:
                    HStack(spacing: 8) {
                        Image(systemName: "doc.fill")
                            .font(.title3)
                            .foregroundStyle(isFromCurrentUser ? .white : AppTheme.accent)
                        Text(message.fileName ?? "File")
                            .font(.subheadline)
                            .foregroundStyle(isFromCurrentUser ? .white : AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? AppTheme.accent : AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isFromCurrentUser ? "You" : "Staff") said: \(message.content ?? message.messageType.rawValue), \(message.createdAt.formatted(date: .omitted, time: .shortened))")
    }

    // MARK: - Helpers

    private static func formatVoiceDuration(_ duration: TimeInterval?) -> String {
        guard let duration, duration > 0 else { return "Voice" }
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
