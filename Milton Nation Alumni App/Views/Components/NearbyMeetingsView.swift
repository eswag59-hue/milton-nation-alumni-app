import SwiftUI
import MapKit

/// Full section view: Map with pins + scrollable card list.
/// Manages its own ViewModel and reacts to location updates.
struct NearbyMeetingsView: View {
    @State private var viewModel = NearbyMeetingsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else if let error = viewModel.errorMessage, viewModel.meetings.isEmpty {
                errorState(error)
            } else if viewModel.meetings.isEmpty && !viewModel.hasRequestedLocation {
                emptyState
            } else if !viewModel.meetings.isEmpty {
                meetingsContent
            } else {
                // Waiting for location — show loading
                loadingState
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: viewModel.locationService.currentLocation) { _, newLocation in
            if let location = newLocation {
                viewModel.fetchMeetings(for: location)
            }
        }
        .onChange(of: viewModel.locationService.authorizationStatus) { _, _ in
            viewModel.handleAuthorizationChange()
        }
    }

    // MARK: - Main Content

    private var meetingsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Map with pins for all meetings
                mapView
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .padding(.horizontal)

                // Section header
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text("Nearest \(viewModel.meetings.count) Meetings")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal)

                // Meeting cards
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.meetings) { meeting in
                        NearbyMeetingCard(meeting: meeting)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map {
            // Show user's current location as blue dot
            UserAnnotation()

            ForEach(viewModel.meetings) { meeting in
                Marker(meeting.name, coordinate: meeting.coordinate)
                    .tint(AppTheme.accent)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .mapStyle(.standard(elevation: .flat))
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView("Finding nearby meetings\u{2026}")
                .foregroundStyle(AppTheme.textSecondary)
            Text("Using your location to search")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Error

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "location.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("Unable to Find Meetings")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                viewModel.locationService.requestCurrentLocation()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(AppTheme.accent)
                .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("No meetings nearby")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Try expanding your search radius")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
    }
}
