import SwiftUI
import EventKit

struct MeetingsScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = MeetingsViewModel()
    @State private var showCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var selectedTab: MeetingsTab = .miltonMeetings

    // MARK: - Tab Enum

    private enum MeetingsTab: String, CaseIterable {
        case miltonMeetings = "Milton"
        case nearbySupport = "Nearby"

        var icon: String {
            switch self {
            case .miltonMeetings: return "building.2.fill"
            case .nearbySupport: return "location.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with logo
                ZStack {
                    MiltonLogoView(size: .small)
                    HStack {
                        Spacer()
                        Text("Meetings")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)

                Divider()

                // Tab selector: Milton | Nearby
                tabSelector
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Content based on selected tab
                if selectedTab == .miltonMeetings {
                    miltonMeetingsContent
                } else {
                    NearbyMeetingsView()
                }
            }
            .background(AppTheme.background)
            .onAppear {
                viewModel.loadMeetings()
            }
            .sheet(item: $viewModel.selectedMeeting) { meeting in
                meetingDetailSheet(meeting: meeting)
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(MeetingsTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption2)
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                    .background(isSelected ? AppTheme.accent : AppTheme.cardBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(
                            isSelected ? Color.clear : AppTheme.divider,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue + " meetings")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer()
        }
    }

    // MARK: - Milton Meetings Content

    @ViewBuilder
    private var miltonMeetingsContent: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Loading meetings\u{2026}")
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        } else if let error = viewModel.errorMessage, viewModel.meetings.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                Text("Connection Error")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button {
                    viewModel.loadMeetings()
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
            }
            Spacer()
        } else if viewModel.meetings.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                Text("No meetings found")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Check back soon for upcoming meetings")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Search meetings\u{2026}", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AppTheme.textPrimary)
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppTheme.divider, lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Meeting cards
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredMeetings) { meeting in
                            meetingRow(meeting: meeting)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Meeting Row

    private func meetingRow(meeting: Meeting) -> some View {
        Button {
            viewModel.selectedMeeting = meeting
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Title + type badge
                HStack {
                    Text(meeting.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    typeBadge(meeting.meetingType)
                }

                // Description
                if let description = meeting.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Date & Time
                HStack(spacing: 16) {
                    Label(meeting.formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Label(meeting.formattedTimeRange, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Location
                if let address = meeting.locationAddress {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }

                // Action row
                HStack(spacing: 10) {
                    // Virtual link
                    if meeting.virtualLink != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                            Text("Virtual")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                    }

                    // RSVP indicator
                    if meeting.meetingType == .inPerson || meeting.meetingType == .hybrid {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.rsvpMeetingIds.contains(meeting.id) ? "checkmark.circle.fill" : "hand.raised.fill")
                            Text(viewModel.rsvpMeetingIds.contains(meeting.id) ? "RSVP'd" : "RSVP")
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(viewModel.rsvpMeetingIds.contains(meeting.id) ? .white : AppTheme.accentSage)
                        .background(AppTheme.accentSage.opacity(viewModel.rsvpMeetingIds.contains(meeting.id) ? 1.0 : 0.12))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    if meeting.isRecurring {
                        Label(
                            meeting.recurrencePattern?.rawValue.capitalized ?? "Recurring",
                            systemImage: "repeat"
                        )
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(meeting.title)
        .accessibilityHint("Double tap to view meeting details")
    }

    // MARK: - Meeting Detail Sheet

    private func meetingDetailSheet(meeting: Meeting) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Type badge
                    HStack {
                        Image(systemName: meeting.meetingType.iconName)
                        Text(meeting.meetingType.displayName)
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(meetingTypeColor(meeting.meetingType))
                    .clipShape(Capsule())

                    // Title
                    Text(meeting.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    // Date & Time
                    HStack(spacing: 12) {
                        Label(meeting.formattedDate, systemImage: "calendar")
                        Label(meeting.formattedTimeRange, systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)

                    // Description
                    if let description = meeting.description {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.white)
                    }

                    // Location (tappable → Apple Maps directions)
                    if let address = meeting.locationAddress {
                        Button {
                            let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "https://maps.apple.com/?daddr=\(encoded)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.white)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.leading)
                                    Text("Tap for directions")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }
                        .accessibilityLabel("Get directions to \(address)")
                        .accessibilityHint("Double tap to open Apple Maps with directions")
                    }

                    // Virtual link
                    if let link = meeting.virtualLink, let url = URL(string: link) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "video.fill")
                                    .foregroundStyle(.white)
                                Text("Join Virtual Meeting")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }
                    }

                    // RSVP button
                    if meeting.meetingType == .inPerson || meeting.meetingType == .hybrid {
                        Button {
                            viewModel.toggleRSVP(for: meeting.id)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.rsvpMeetingIds.contains(meeting.id) ? "checkmark.circle.fill" : "hand.raised.fill")
                                Text(viewModel.rsvpMeetingIds.contains(meeting.id) ? "You're RSVP'd!" : "RSVP for In-Person")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(viewModel.rsvpMeetingIds.contains(meeting.id) ? .white : AppTheme.accentSage)
                            .background(AppTheme.accentSage.opacity(viewModel.rsvpMeetingIds.contains(meeting.id) ? 1.0 : 0.15))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }
                    }

                    // Add to Calendar
                    Button {
                        addMeetingToCalendar(meeting)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(.white)
                            Text("Add to Calendar")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    }
                    .accessibilityLabel("Add meeting to calendar")
                    .accessibilityHint("Double tap to save this meeting to your calendar")

                    // Recurrence info
                    if meeting.isRecurring, let pattern = meeting.recurrencePattern {
                        HStack(spacing: 8) {
                            Image(systemName: "repeat")
                                .foregroundStyle(.white.opacity(0.8))
                            Text("Repeats \(pattern.rawValue)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.sheetBackground.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .padding(.horizontal, 4)
            }
            .background(AppTheme.sheetBackground)
            .navigationTitle("Meeting Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.selectedMeeting = nil
                    }
                }
            }
            .alert("Calendar", isPresented: $showCalendarAlert) {
                Button("OK") {}
            } message: {
                Text(calendarAlertMessage)
            }
        }
    }

    // MARK: - Helpers

    private func typeBadge(_ type: MeetingType) -> some View {
        let color: Color = {
            switch type {
            case .inPerson: return AppTheme.winsColor
            case .virtual: return AppTheme.accent
            case .hybrid: return AppTheme.gratitudeColor
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: type.iconName)
                .font(.caption2)
            Text(type.displayName)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func meetingTypeColor(_ type: MeetingType) -> Color {
        switch type {
        case .inPerson: return AppTheme.accent
        case .virtual: return AppTheme.accentMedium
        case .hybrid: return AppTheme.accentSage
        }
    }

    // MARK: - Calendar Integration

    private func addMeetingToCalendar(_ meeting: Meeting) {
        let store = EKEventStore()
        store.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted {
                    createCalendarEvent(in: store, for: meeting)
                } else {
                    calendarAlertMessage = "Calendar access was denied. Please enable it in Settings > Privacy > Calendars."
                    showCalendarAlert = true
                }
            }
        }
    }

    private func createCalendarEvent(in store: EKEventStore, for meeting: Meeting) {
        let event = EKEvent(eventStore: store)
        event.title = meeting.title
        event.startDate = meeting.startTime
        event.endDate = meeting.endTime
        event.location = meeting.locationAddress
        if let description = meeting.description {
            event.notes = description
        }
        event.addAlarm(EKAlarm(relativeOffset: -1800))

        guard let calendar = store.defaultCalendarForNewEvents else {
            calendarAlertMessage = "No calendar is configured on this device. Please add a calendar in Settings."
            showCalendarAlert = true
            return
        }
        event.calendar = calendar

        do {
            try store.save(event, span: .thisEvent)
            calendarAlertMessage = "\"\(meeting.title)\" has been added to your calendar."
            showCalendarAlert = true
        } catch {
            calendarAlertMessage = "Failed to save event: \(error.localizedDescription)"
            showCalendarAlert = true
        }
    }
}
