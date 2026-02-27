import SwiftUI

struct AnnouncementCard: View {
    let announcements: [Announcement]
    @State private var expandedIds: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Updates & News")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            if announcements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                    Text("No announcements yet")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(Array(announcements.enumerated()), id: \.element.id) { index, announcement in
                    let isExpanded = expandedIds.contains(announcement.id)

                    if index > 0 {
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if isExpanded {
                                    expandedIds.remove(announcement.id)
                                } else {
                                    expandedIds.insert(announcement.id)
                                }
                            }
                        } label: {
                            HStack {
                                Text(announcement.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)

                        Text(announcement.description)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)

                        Text(announcement.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}
