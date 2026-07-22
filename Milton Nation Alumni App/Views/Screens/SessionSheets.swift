import SwiftUI

// MARK: - Request a session (client)

/// A client asks for a session with any provider (not just their care team),
/// at a primary or backup time. It lands as a `requested` appointment; a
/// scheduler or the requested clinician approves it later.
struct RequestSessionSheet: View {
    @Bindable var vm: AppointmentsViewModel
    let client: User?
    /// Called with true once a request is successfully sent, so the parent can
    /// show the "your care team has been notified" confirmation.
    var onRequested: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var providerId: UUID?
    @State private var type: AppointmentType = .individualTherapy
    @State private var purpose = ""
    @State private var preferredStart = Date().addingTimeInterval(86_400)
    @State private var useBackup = false
    @State private var backupStart = Date().addingTimeInterval(172_800)
    @State private var submitting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if vm.bookableProviders.isEmpty {
                    Section {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                } else {
                    Section("Who would you like to see?") {
                        Picker("Provider", selection: $providerId) {
                            Text("Select…").tag(UUID?.none)
                            ForEach(vm.bookableProviders) { p in
                                Text("\(p.fullName) · \(p.roleLabel)").tag(UUID?.some(p.id))
                            }
                        }
                    }
                    Section {
                        Picker("Type", selection: $type) {
                            ForEach(AppointmentType.allCases) { t in
                                Label(t.displayName, systemImage: t.icon).tag(t)
                            }
                        }
                        TextField("What's it about? (optional)", text: $purpose, axis: .vertical)
                            .lineLimit(2...4)
                    } header: {
                        Text("Session")
                    }
                    Section {
                        DatePicker("Ideal time", selection: $preferredStart,
                                   in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        Toggle("Add a backup time", isOn: $useBackup)
                        if useBackup {
                            DatePicker("Backup time", selection: $backupStart,
                                       in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        }
                    } header: {
                        Text("When works for you?")
                    } footer: {
                        Text("A scheduler will confirm the provider and one of these times, then it appears in your sessions.")
                    }
                    if let error {
                        Section { Text(error).font(.caption).foregroundStyle(.red) }
                    }
                }
            }
            .navigationTitle("Request a Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Request") { Task { await submit() } }
                        .disabled(providerId == nil || submitting)
                }
            }
            .task { await vm.loadBookableProviders() }
        }
    }

    private func submit() async {
        guard let client, let providerId else { return }
        submitting = true; error = nil
        let ok = await vm.requestSession(
            clientId: client.id, preferredProviderId: providerId, facility: client.facility,
            type: type, purpose: purpose.isEmpty ? nil : purpose,
            preferredStart: preferredStart, preferredStart2: useBackup ? backupStart : nil
        )
        submitting = false
        if ok { onRequested(); dismiss() }
        else { error = vm.errorMessage ?? "Couldn't send the request." }
    }
}

// MARK: - Session detail (both sides)

struct SessionDetailSheet: View {
    let appt: Appointment
    let vm: AppointmentsViewModel
    let perspective: SessionPerspective

    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    private var counterpart: String {
        perspective == .client ? (appt.providerName ?? "Your provider")
                               : (appt.clientName ?? "Client")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: appt.appointmentType.icon)
                            .font(.system(size: 30))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 68, height: 68)
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(Circle())
                        Text(appt.appointmentType.displayName)
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        StatusPill(status: appt.status)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    .background(AppTheme.cardBackground).clipShape(RoundedRectangle(cornerRadius: 14))

                    detailRows

                    if appt.canJoin, let url = appt.zoomJoinUrl, let link = URL(string: url) {
                        Link(destination: link) {
                            Label("Join Session", systemImage: "video.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(AppTheme.primary).foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else if appt.status == .confirmed && appt.zoomJoinUrl == nil {
                        Text("The video link will appear here once it's set up.")
                            .font(.caption).foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if perspective == .staff && appt.status == .requested {
                        Button {
                            Task { working = true; _ = await vm.updateStatus(appt, to: .confirmed); working = false; dismiss() }
                        } label: {
                            Text("Confirm Session").fontWeight(.semibold)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(.green).foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }.disabled(working)
                    }

                    if appt.status == .confirmed || appt.status == .requested {
                        Button(role: .destructive) {
                            Task { working = true; _ = await vm.updateStatus(appt, to: .cancelled); working = false; dismiss() }
                        } label: {
                            Text("Cancel Session")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }.disabled(working)
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var detailRows: some View {
        VStack(spacing: 0) {
            row("person.fill", perspective == .client ? "Provider" : "Client", counterpart)
            Divider()
            row("calendar", "When", appt.formattedWhen)
            Divider()
            row("clock", "Duration", "\(appt.durationMinutes) min")
            if let purpose = appt.purpose, !purpose.isEmpty {
                Divider(); row("text.alignleft", "About", purpose)
            }
            if perspective == .staff, let note = appt.staffNote, !note.isEmpty {
                Divider(); row("note.text", "Staff note", note)
            }
        }
        .background(AppTheme.cardBackground).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func row(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundStyle(AppTheme.accent).frame(width: 18)
            Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary)
            Spacer(minLength: 12)
            Text(value).font(.caption.weight(.medium)).foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
    }
}

// MARK: - Post-session feedback (client)

struct SessionFeedbackSheet: View {
    let appt: Appointment
    let vm: AppointmentsViewModel
    let clientId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var reflection = ""
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("How was your session?") {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(star <= rating ? .yellow : AppTheme.textSecondary.opacity(0.4))
                                .onTapGesture { rating = star }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                Section("Your private notes (optional)") {
                    TextField("Anything you want to remember…", text: $reflection, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Rate Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Skip") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }.disabled(rating == 0 || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        let ok = await vm.submitFeedback(appointmentId: appt.id, clientId: clientId,
                                         rating: rating, reflection: reflection.isEmpty ? nil : reflection)
        saving = false
        if ok { dismiss() }
    }
}

// MARK: - Approve a request (scheduler / clinician)

/// Review a client's session request: keep or override the provider, pick the
/// final time (one of the two the client suggested, or a custom time), then
/// approve — which confirms it onto both schedules — or decline it.
struct ApproveSessionSheet: View {
    let appt: Appointment
    @Bindable var vm: AppointmentsViewModel
    let approvedBy: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var providerId: UUID?
    @State private var timeChoice: TimeChoice = .primary
    @State private var customStart = Date().addingTimeInterval(86_400)
    @State private var working = false
    @State private var error: String?

    private enum TimeChoice: Hashable { case primary, backup, custom }

    private var chosenStart: Date {
        switch timeChoice {
        case .primary: return appt.preferredStart ?? customStart
        case .backup:  return appt.preferredStart2 ?? customStart
        case .custom:  return customStart
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Request") {
                    row("Client", appt.clientName ?? "Client")
                    row("Requested", appt.providerName ?? "—")
                    row("Type", appt.appointmentType.displayName)
                    if let p = appt.purpose, !p.isEmpty { row("About", p) }
                }

                Section("Assign provider") {
                    Picker("Provider", selection: $providerId) {
                        ForEach(vm.bookableProviders) { p in
                            Text("\(p.fullName) · \(p.roleLabel)").tag(UUID?.some(p.id))
                        }
                    }
                }

                Section("Confirm the time") {
                    Picker("Time", selection: $timeChoice) {
                        if appt.preferredStart != nil { Text("Ideal").tag(TimeChoice.primary) }
                        if appt.preferredStart2 != nil { Text("Backup").tag(TimeChoice.backup) }
                        Text("Custom").tag(TimeChoice.custom)
                    }
                    .pickerStyle(.segmented)

                    if let t = appt.preferredStart, timeChoice == .primary {
                        Text(t.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    } else if let t = appt.preferredStart2, timeChoice == .backup {
                        Text(t.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    } else {
                        DatePicker("Start", selection: $customStart, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }

                if let error {
                    Section { Text(error).font(.caption).foregroundStyle(.red) }
                }

                Section {
                    Button {
                        Task { await declineRequest() }
                    } label: {
                        Text("Decline request").foregroundStyle(.red)
                    }.disabled(working)
                }
            }
            .navigationTitle("Approve Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Approve") { Task { await approve() } }
                        .disabled(providerId == nil || working)
                }
            }
            .task {
                await vm.loadBookableProviders()
                // Default the assignment to who the client asked for.
                providerId = appt.requestedProviderId ?? appt.providerId
                if appt.preferredStart == nil { timeChoice = .custom }
            }
        }
    }

    private func approve() async {
        guard let providerId else { return }
        working = true; error = nil
        let ok = await vm.approve(appt, providerId: providerId, at: chosenStart, approvedBy: approvedBy)
        working = false
        if ok { dismiss() } else { error = vm.errorMessage ?? "Couldn't approve. Try again." }
    }

    private func declineRequest() async {
        working = true; error = nil
        let ok = await vm.decline(appt)
        working = false
        if ok { dismiss() } else { error = vm.errorMessage ?? "Couldn't decline. Try again." }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(AppTheme.textPrimary).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
