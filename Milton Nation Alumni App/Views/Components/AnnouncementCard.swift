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

                    // Whole-card tap target so users can tap anywhere on the
                    // announcement row (title, body, date, empty space) to
                    // expand/collapse — not just the small chevron.
                    VStack(alignment: .leading, spacing: 4) {
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

                        Text(announcement.description)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)

                        Text(announcement.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())   // make the WHOLE area tappable
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if isExpanded {
                                expandedIds.remove(announcement.id)
                            } else {
                                expandedIds.insert(announcement.id)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(announcement.title). \(isExpanded ? "Expanded." : "Collapsed.") Tap to \(isExpanded ? "collapse" : "expand").")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}
