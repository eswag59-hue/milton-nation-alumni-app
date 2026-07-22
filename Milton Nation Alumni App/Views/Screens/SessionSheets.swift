import SwiftUI

// MARK: - Request a session (client)

/// A client asks their care team for a session. It lands as `requested`; a
/// provider confirms and the video link is attached then.
struct RequestSessionSheet: View {
    let vm: AppointmentsViewModel
    let client: User?
    let providers: [User]

    @Environment(\.dismiss) private var dismiss
    @State private var providerId: UUID?
    @State private var type: AppointmentType = .individualTherapy
    @State private var purpose = ""
    @State private var preferredStart = Date().addingTimeInterval(86_400)
    @State private var submitting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if providers.isEmpty {
                    Section {
                        Text("You don't have a care team assigned yet. Reach out through Chat and an admin will connect you.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Section("Provider") {
                        Picker("With", selection: $providerId) {
                            Text("Select…").tag(UUID?.none)
                            ForEach(providers) { p in
                                Text(p.fullName).tag(UUID?.some(p.id))
                            }
                        }
                    }
                    Section("Session") {
                        Picker("Type", selection: $type) {
                            ForEach(AppointmentType.allCases) { t in
                                Label(t.displayName, systemImage: t.icon).tag(t)
                            }
                        }
                        TextField("What's it about? (optional)", text: $purpose, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    Section("Preferred time") {
                        DatePicker("Ideally", selection: $preferredStart,
                                   in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    }
                    if let error {
                        Section { Text(error).font(.caption).foregroundStyle(.red) }
                    }
                }
            }
            .navigationTitle("Request Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { Task { await submit() } }
                        .disabled(providerId == nil || submitting)
                }
            }
        }
    }

    private func submit() async {
        guard let client, let providerId else { return }
        submitting = true; error = nil
        let ok = await vm.requestSession(
            clientId: client.id, providerId: providerId, facility: client.facility,
            type: type, purpose: purpose.isEmpty ? nil : purpose, preferredStart: preferredStart
        )
        submitting = false
        if ok { dismiss() } else { error = vm.errorMessage ?? "Couldn't send the request." }
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
