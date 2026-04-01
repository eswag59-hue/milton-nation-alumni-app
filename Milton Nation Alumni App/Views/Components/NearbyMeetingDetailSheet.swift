import SwiftUI
import MapKit

/// Full-detail sheet shown when a meeting card is tapped.
/// Displays all meeting information with plain-English format descriptions
/// and dual direction buttons (Apple Maps + Waze).
struct NearbyMeetingDetailSheet: View {
    let meeting: BMTLMeeting
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Header
                    headerSection

                    Divider().background(AppTheme.textSecondary.opacity(0.3))

                    // MARK: - When
                    detailSection(title: "When", systemImage: "calendar") {
                        infoRow(label: "Day", value: meeting.weekdayName)
                        infoRow(label: "Time", value: meeting.formattedStartTime)
                        if !meeting.formattedDuration.isEmpty {
                            infoRow(label: "Duration", value: meeting.formattedDuration)
                        }
                    }

                    Divider().background(AppTheme.textSecondary.opacity(0.3))

                    // MARK: - Where
                    detailSection(title: "Where", systemImage: "mappin.and.ellipse") {
                        if !meeting.locationName.isEmpty {
                            infoRow(label: "Venue", value: meeting.locationName)
                        }
                        if !meeting.streetAddress.isEmpty {
                            infoRow(label: "Address", value: meeting.fullAddress)
                        }
                    }

                    Divider().background(AppTheme.textSecondary.opacity(0.3))

                    // MARK: - Meeting Format
                    let formats = meeting.decodedFormats
                    if !formats.isEmpty {
                        formatSection(formats: formats)
                        Divider().background(AppTheme.textSecondary.opacity(0.3))
                    }

                    // MARK: - Directions Buttons
                    directionsSection

                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(meeting.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(meeting.name)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    // Fellowship badge
                    Text(meeting.fellowship.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(meeting.fellowship == .aa ? Color.blue : AppTheme.accentSage)
                        .clipShape(Capsule())

                    // Distance badge
                    if !meeting.formattedDistance.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(meeting.formattedDistance)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - Format Section

    private func formatSection(formats: [(label: String, detail: String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Meeting Format", systemImage: "list.bullet.clipboard")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(formats, id: \.label) { fmt in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fmt.label)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(fmt.detail)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.sheetBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                }
            }
        }
    }

    // MARK: - Directions Section

    private var directionsSection: some View {
        VStack(spacing: 10) {
            Button {
                openAppleMaps()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                    Text("Directions in Apple Maps")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .accessibilityLabel("Get directions to \(meeting.name) in Apple Maps")

            Button {
                openWaze()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("Directions in Waze")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(AppTheme.accent)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                )
            }
            .accessibilityLabel("Get directions to \(meeting.name) in Waze")
        }
    }

    // MARK: - Helper Views

    private func detailSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.accent)
            content()
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Map Openers

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
