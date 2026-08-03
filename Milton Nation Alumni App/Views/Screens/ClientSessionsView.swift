import SwiftUI

/// The client's private telehealth surface: upcoming 1:1 sessions with their
/// care team, a way to request one, join when it's time, and reflect after.
/// Lives inside the Schedule tab alongside community meetings.
struct ClientSessionsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var vm = AppointmentsViewModel()
    @State private var showRequest = false
    @State private var showRequestedConfirmation = false
    @State private var selected: Appointment?
    @State private var rating: Appointment?

    private var me: User? { appViewModel.currentUser }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                requestButton

                if vm.isLoading && vm.appointments.isEmpty {
                    ProgressView().padding(.top, 40)
                } else if vm.upcoming.isEmpty && vm.past.isEmpty {
                    emptyState
                } else {
                    if !vm.upcoming.isEmpty {
                        section("Upcoming") {
                            ForEach(vm.upcoming) { appt in
                                SessionCard(appt: appt, perspective: .client)
                                    .onTapGesture { selected = appt }
                            }
                        }
                    }
                    if !vm.past.isEmpty {
                        section("Past") {
                            ForEach(vm.past) { appt in
                                SessionCard(appt: appt, perspective: .client,
                                            showRate: appt.isRatable && vm.feedbackByAppointment[appt.id] == nil)
                                    .onTapGesture {
                                        if appt.isRatable && vm.feedbackByAppointment[appt.id] == nil {
                                            rating = appt
                                        } else {
                                            selected = appt
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(AppTheme.background)
        .refreshable {
            await vm.load()
            await vm.loadBookableProviders()
            vm.fillProviderNames()
        }
        .task {
            await vm.load()
            // Resolve provider names the profiles RLS hides from the client.
            await vm.loadBookableProviders()
            vm.fillProviderNames()
            for appt in vm.past where appt.isRatable {
                await vm.loadFeedback(for: appt.id)
            }
        }
        .sheet(isPresented: $showRequest) {
            RequestSessionSheet(vm: vm, client: me, onRequested: { showRequestedConfirmation = true })
        }
        .alert("Request sent", isPresented: $showRequestedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            // Honest wording: the request is queued for the care team to review
            // in their scheduling console — we don't claim a push went out to
            // them (it doesn't yet). The client IS notified once it's approved.
            Text("Your request is in. Your care team will review it and confirm a time — you'll get a notification here once it's scheduled.")
        }
        .sheet(item: $selected) { appt in
            SessionDetailSheet(appt: appt, vm: vm, perspective: .client)
        }
        .sheet(item: $rating) { appt in
            SessionFeedbackSheet(appt: appt, vm: vm, clientId: me?.id ?? appt.clientId)
        }
    }

    private var requestButton: some View {
        Button {
            showRequest = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                Text("Request a session").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            Text("No sessions yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Request a session with your care team and it'll show up here.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
        .padding(.horizontal, 40)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal)
            content()
        }
    }
}

// MARK: - Session card (shared by client + staff lists)

enum SessionPerspective { case client, staff }

struct SessionCard: View {
    let appt: Appointment
    let perspective: SessionPerspective
    var showRate: Bool = false

    private var counterpartName: String {
        switch perspective {
        case .client: return appt.providerName ?? "Your provider"
        case .staff:  return appt.clientName ?? "Client"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: appt.appointmentType.icon)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40, height: 40)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(appt.appointmentType.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(counterpartName)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(appt.formattedWhen)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusPill(status: appt.status)
                if appt.canJoin, let url = appt.zoomJoinUrl, let link = URL(string: url) {
                    Link(destination: link) {
                        Text("Join")
                            .font(.caption2.bold())
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(AppTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                } else if showRate {
                    Text("Tap to rate")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

struct StatusPill: View {
    let status: AppointmentStatus
    private var color: Color {
        switch status {
        case .confirmed: return .green
        case .requested: return .orange
        case .completed: return AppTheme.accent
        case .cancelled, .noShow: return .red
        }
    }
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
