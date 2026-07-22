import SwiftUI

/// The provider's scheduling console: pending requests to confirm, their own
/// upcoming agenda, and a one-tap flow to schedule a session with any client
/// on their caseload. Shown as a tab for case managers / therapists / admins.
struct StaffScheduleScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var vm = AppointmentsViewModel()
    @State private var chat = ChatViewModel()     // caseload lives here
    @State private var showSchedule = false
    @State private var selected: Appointment?

    /// Caseload as (clientId, name) pairs — `staffName` carries the client's
    /// name in the staff view.
    private var clients: [(id: UUID, name: String)] {
        chat.conversations.map { ($0.userId, $0.staffName) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scheduleButton

                    if vm.isLoading && vm.appointments.isEmpty {
                        ProgressView().padding(.top, 40)
                    } else {
                        if !vm.pendingRequests.isEmpty {
                            section("Requests to confirm") {
                                ForEach(vm.pendingRequests) { appt in
                                    SessionCard(appt: appt, perspective: .staff)
                                        .onTapGesture { selected = appt }
                                }
                            }
                        }
                        if !vm.upcoming.filter({ $0.status == .confirmed }).isEmpty {
                            section("Your agenda") {
                                ForEach(vm.upcoming.filter { $0.status == .confirmed }) { appt in
                                    SessionCard(appt: appt, perspective: .staff)
                                        .onTapGesture { selected = appt }
                                }
                            }
                        }
                        if !vm.past.isEmpty {
                            section("Past") {
                                ForEach(vm.past) { appt in
                                    SessionCard(appt: appt, perspective: .staff)
                                        .onTapGesture { selected = appt }
                                }
                            }
                        }
                        if vm.appointments.isEmpty { emptyState }
                    }
                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("Schedule")
            .refreshable { await vm.load() }
            .task {
                await vm.load()
                chat.loadConversations()
            }
            .sheet(isPresented: $showSchedule) {
                ScheduleSessionSheet(vm: vm, provider: appViewModel.currentUser, clients: clients)
            }
            .sheet(item: $selected) { appt in
                // A pending request opens the approval flow (pick provider +
                // time); anything already scheduled opens read-only details.
                if appt.status == .requested, let uid = appViewModel.currentUser?.id {
                    ApproveSessionSheet(appt: appt, vm: vm, approvedBy: uid)
                } else {
                    SessionDetailSheet(appt: appt, vm: vm, perspective: .staff)
                }
            }
        }
    }

    private var scheduleButton: some View {
        Button { showSchedule = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                Text("Schedule a session").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .foregroundStyle(.white).background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 40)).foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("No sessions scheduled").font(.headline).foregroundStyle(AppTheme.textPrimary)
            Text("Schedule a session with a client to get started.")
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 40).padding(.horizontal, 40)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary).padding(.horizontal)
            content()
        }
    }
}

// MARK: - Schedule a session (staff)

struct ScheduleSessionSheet: View {
    let vm: AppointmentsViewModel
    let provider: User?
    let clients: [(id: UUID, name: String)]

    @Environment(\.dismiss) private var dismiss
    @State private var clientId: UUID?
    @State private var type: AppointmentType = .individualTherapy
    @State private var purpose = ""
    @State private var start = Date().addingTimeInterval(3600)
    @State private var duration = 50
    @State private var note = ""
    @State private var saving = false
    @State private var error: String?

    private let durations = [15, 30, 45, 50, 60, 90]

    var body: some View {
        NavigationStack {
            Form {
                if clients.isEmpty {
                    Section {
                        Text("No clients on your caseload yet. Once clients are assigned to you, they'll appear here.")
                            .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Section("Client") {
                        Picker("With", selection: $clientId) {
                            Text("Select…").tag(UUID?.none)
                            ForEach(clients, id: \.id) { c in
                                Text(c.name).tag(UUID?.some(c.id))
                            }
                        }
                    }
                    Section("Session") {
                        Picker("Type", selection: $type) {
                            ForEach(AppointmentType.allCases) { t in
                                Label(t.displayName, systemImage: t.icon).tag(t)
                            }
                        }
                        TextField("What it's for (optional)", text: $purpose, axis: .vertical)
                            .lineLimit(1...3)
                    }
                    Section("When") {
                        DatePicker("Start", selection: $start, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                        Picker("Duration", selection: $duration) {
                            ForEach(durations, id: \.self) { Text("\($0) min").tag($0) }
                        }
                    }
                    Section("Private staff note (optional)") {
                        TextField("Not shown to the client", text: $note, axis: .vertical)
                            .lineLimit(1...3)
                    }
                    if let error {
                        Section { Text(error).font(.caption).foregroundStyle(.red) }
                    }
                }
            }
            .navigationTitle("Schedule Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") { Task { await save() } }
                        .disabled(clientId == nil || saving)
                }
            }
        }
    }

    private func save() async {
        guard let provider, let clientId else { return }
        saving = true; error = nil
        // A provider schedules within their own facility; adminFacility for
        // staff, falling back to their facility field.
        let facility = provider.adminFacility ?? provider.facility
        let ok = await vm.scheduleSession(
            clientId: clientId, providerId: provider.id, facility: facility,
            type: type, purpose: purpose.isEmpty ? nil : purpose,
            start: start, durationMinutes: duration, staffNote: note.isEmpty ? nil : note
        )
        saving = false
        if ok { dismiss() } else { error = vm.errorMessage ?? "Couldn't schedule the session." }
    }
}
