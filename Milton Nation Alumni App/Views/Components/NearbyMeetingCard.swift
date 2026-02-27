import SwiftUI
import MapKit

/// A single card displaying a BMLT meeting with dark background
/// and pure white text for high contrast legibility.
struct NearbyMeetingCard: View {
    let meeting: BMTLMeeting

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Meeting name + distance badge
            HStack {
                Text(meeting.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                if !meeting.formattedDistance.isEmpty {
                    Text(meeting.formattedDistance)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                }
            }

            // Day + Time
            HStack(spacing: 12) {
                Label(meeting.weekdayName, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Label(meeting.formattedStartTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Address
            if !meeting.fullAddress.isEmpty {
                Label(meeting.fullAddress, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            // Location name
            if !meeting.locationName.isEmpty {
                Text(meeting.locationName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Formats
            if !meeting.formats.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                    Text(meeting.formats)
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.7))
            }

            // Get Directions button
            Button {
                openDirections()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Get Directions")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            }
            .accessibilityLabel("Get directions to \(meeting.name)")
            .accessibilityHint("Opens Apple Maps with driving directions")
        }
        .padding()
        .background(AppTheme.sheetBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.name), \(meeting.weekdayName) at \(meeting.formattedStartTime), \(meeting.formattedDistance)")
    }

    // MARK: - Directions

    private func openDirections() {
        let placemark = MKPlacemark(coordinate: meeting.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = meeting.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
