import SwiftUI

/// Sheet for admin/super_admin to create or edit a Milton-organized meeting.
struct AddEditMeetingSheet: View {
    let existingMeeting: Meeting?
    let currentUserId: UUID
    /// Facility of the staff member authoring this meeting. Nil for super
    /// admins, who may author for either facility.
    var authorFacility: Facility? = nil
    var authorIsSuperAdmin: Bool = false
    let onSave: (Meeting) async -> Void
    let onDelete: ((UUID) async -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var title = ""
    @State private var description = ""
    @State private var meetingType: MeetingType = .inPerson
    @State private var startTime = Date().roundedToNextHour()
    @State private var endTime = Date().roundedToNextHour().addingTimeInterval(3600)
    @State private var locationAddress = ""
    @State private var virtualLink = ""
    @State private var isRecurring = false
    @State private var recurrencePattern: RecurrencePattern = .weekly
    @State private var recurrenceEndDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    /// nil == visible to BOTH facilities.
    @State private var facility: Facility? = nil
    @State private var didInitFacility = false

    @State private var showDeleteConfirm = false
    @State private var isSaving = false

    private var isEditing: Bool { existingMeeting != nil }

    /// Super admins may author for either facility; facility staff may author
    /// for their own facility or for both (shared virtual meetings), but never
    /// for the other facility.
    private var selectableFacilities: [Facility?] {
        if authorIsSuperAdmin || authorFacility == nil {
            return [.florida, .ohio, nil]
        }
        return [authorFacility, nil]
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        endTime > startTime
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Basic Info
                Section("Meeting Details") {
                    TextField("Title (required)", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("Type", selection: $meetingType) {
                        ForEach(MeetingType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }

                // MARK: Facility
                Section {
                    Picker("Visible to", selection: $facility) {
                        ForEach(selectableFacilities, id: \.self) { f in
                            Text(f?.displayName ?? "Both facilities").tag(f)
                        }
                    }
                } header: {
                    Text("Facility")
                } footer: {
                    Text(facility == nil
                         ? "Members at both Florida and Ohio will see this meeting. Use for virtual meetings open to everyone."
                         : "Only \(facility?.displayName ?? "") members will see this meeting.")
                }

                // MARK: Date & Time
                Section("Date & Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: startTime) { _, newStart in
                            if endTime <= newStart {
                                endTime = newStart.addingTimeInterval(3600)
                            }
                        }
                    DatePicker("End", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                }

                // MARK: Location / Virtual
                if meetingType == .inPerson || meetingType == .hybrid {
                    Section("Location") {
                        TextField("Address (e.g. 123 Main St, Miami, FL)", text: $locationAddress)
                    }
                }

                if meetingType == .virtual || meetingType == .hybrid {
                    Section("Virtual Link") {
                        TextField("https://zoom.us/j/...", text: $virtualLink)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                // MARK: Recurrence
                Section {
                    Toggle("Recurring Meeting", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Repeats", selection: $recurrencePattern) {
                            ForEach(RecurrencePattern.allCases, id: \.self) { pattern in
                                Text(pattern.rawValue.capitalized).tag(pattern)
                            }
                        }
                        DatePicker("Until", selection: $recurrenceEndDate, in: startTime..., displayedComponents: .date)
                    }
                } header: {
                    Text("Recurrence")
                }

                // MARK: Delete (edit mode only)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Meeting")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Meeting" : "New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Delete this meeting?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let id = existingMeeting?.id {
                        Task {
                            isSaving = true
                            await onDelete?(id)
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .onAppear { populateIfEditing() }
        }
    }

    // MARK: - Populate (edit mode)

    private func populateIfEditing() {
        if !didInitFacility {
            facility = existingMeeting?.facility ?? authorFacility
            didInitFacility = true
        }
        guard let m = existingMeeting else { return }
        title = m.title
        description = m.description ?? ""
        meetingType = m.meetingType
        startTime = m.startTime
        endTime = m.endTime
        locationAddress = m.locationAddress ?? ""
        virtualLink = m.virtualLink ?? ""
        isRecurring = m.isRecurring
        if let pattern = m.recurrencePattern { recurrencePattern = pattern }
        if let end = m.recurrenceEndDate { recurrenceEndDate = end }
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty, endTime > startTime else { return }

        let meeting = Meeting(
            id: existingMeeting?.id ?? UUID(),
            title: trimmedTitle,
            description: description.isEmpty ? nil : description,
            meetingType: meetingType,
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            locationAddress: (meetingType == .virtual) ? nil : (locationAddress.isEmpty ? nil : locationAddress),
            locationLat: existingMeeting?.locationLat,
            locationLng: existingMeeting?.locationLng,
            virtualLink: (meetingType == .inPerson) ? nil : (virtualLink.isEmpty ? nil : virtualLink),
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? recurrencePattern : nil,
            recurrenceEndDate: isRecurring ? recurrenceEndDate : nil,
            parentMeetingId: existingMeeting?.parentMeetingId,
            createdBy: existingMeeting?.createdBy ?? currentUserId,
            createdAt: existingMeeting?.createdAt ?? Date(),
            facility: facility
        )

        Task {
            isSaving = true
            await onSave(meeting)
            dismiss()
        }
    }
}

// MARK: - Date Helper

private extension Date {
    /// Rounds up to the next whole hour.
    func roundedToNextHour() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: self)
        comps.hour = (comps.hour ?? 0) + 1
        comps.minute = 0
        comps.second = 0
        return Calendar.current.date(from: comps) ?? self
    }
}
