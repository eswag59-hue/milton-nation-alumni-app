import SwiftUI

struct MeetingCard: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meeting.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                typeBadge
            }

            if let description = meeting.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label(meeting.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Label(meeting.formattedTimeRange, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let address = meeting.locationAddress {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
                    .lineLimit(1)
            }

            if meeting.virtualLink != nil {
                Label("Virtual link available", systemImage: "video.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }

            if meeting.isRecurring {
                Label(
                    meeting.recurrencePattern == .weekly ? "Weekly" : "Monthly",
                    systemImage: "repeat"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.title), \(meeting.meetingType.displayName), \(meeting.formattedDate) at \(meeting.formattedTimeRange)")
    }

    private var typeBadge: some View {
        let color: Color = {
            switch meeting.meetingType {
            case .inPerson: return AppTheme.winsColor
            case .virtual: return AppTheme.accent
            case .hybrid: return AppTheme.gratitudeColor
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: meeting.meetingType.iconName)
                .font(.caption2)
            Text(meeting.meetingType.displayName)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
