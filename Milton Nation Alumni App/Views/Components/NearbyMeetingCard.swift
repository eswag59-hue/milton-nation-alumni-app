import SwiftUI
import MapKit

/// A single card displaying a BMLT meeting with dark background
/// and pure white text for high contrast legibility.
/// Tap the card to open the full detail sheet.
struct NearbyMeetingCard: View {
    let meeting: BMTLMeeting
    @State private var showDetail = false
    @State private var showDirectionsChoice = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            NearbyMeetingDetailSheet(meeting: meeting)
        }
        .confirmationDialog(
            "Get Directions to \(meeting.name)",
            isPresented: $showDirectionsChoice,
            titleVisibility: .visible
        ) {
            Button("Apple Maps") { openAppleMaps() }
            Button("Waze")      { openWaze() }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Meeting name + distance badge
            HStack {
                Text(meeting.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                HStack(spacing: 6) {
                    // Fellowship badge: AA (blue) or NA (green)
                    Text(meeting.fellowship.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .foregroundStyle(.white)
                        .background(meeting.fellowship == .aa ? Color.blue : AppTheme.accentSage)
                        .clipShape(Capsule())
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

            // Tap hint + Quick Directions row
            HStack(spacing: 8) {
                // "Tap for details" hint
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text("Tap for details")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.55))

                Spacer()

                // Quick Directions button — shows Apple Maps / Waze choice
                Button {
                    showDirectionsChoice = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .foregroundStyle(.white)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Get directions to \(meeting.name)")
                .accessibilityHint("Choose Apple Maps or Waze")
            }
        }
        .padding()
        .background(AppTheme.sheetBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.name), \(meeting.weekdayName) at \(meeting.formattedStartTime), \(meeting.formattedDistance). Tap for more details.")
    }

    // MARK: - Directions

    private func openAppleMaps() {
        let placemark = MKPlacemark(coordinate: meeting.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = meeting.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func openWaze() {
        let lat = meeting.latitude
        let lng = meeting.longitude
        let wazeURL = URL(string: "waze://?ll=\(lat),\(lng)&navigate=yes")
        let webURL  = URL(string: "https://waze.com/ul?ll=\(lat),\(lng)&navigate=yes")!

        if let wazeURL, UIApplication.shared.canOpenURL(wazeURL) {
            UIApplication.shared.open(wazeURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}
