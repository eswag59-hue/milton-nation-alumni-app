import SwiftUI

struct ContentView: View {
    @Bindable var appViewModel: AppViewModel

    var body: some View {
        if appViewModel.isAuthenticated {
            if appViewModel.currentUser?.status == .pending {
                // New user awaiting admin facility assignment + approval
                PendingApprovalScreen()
            } else if appViewModel.currentUser?.role.isAdmin == true && !appViewModel.isViewingAsUser {
                AdminDashboardScreen()
                    .sheet(isPresented: $appViewModel.showFacilityPicker) {
                        FacilityPickerScreen()
                    }
            } else if appViewModel.currentUser?.role == .alumni {
                alumniTabView
                    .sheet(isPresented: $appViewModel.showSobrietyCheck) {
                        SobrietyCheckModal()
                    }
            } else if appViewModel.currentUser?.role.isClinical == true && !appViewModel.isViewingAsUser {
                // Case managers / therapists / counselors get a staff view with
                // their caseload — NOT the patient "recovery journey."
                staffTabView
            } else {
                // Admin in "View as User" mode (or any fallback)
                alumniTabView
            }
        } else {
            LoginScreen(authService: appViewModel.authService)
        }
    }

    /// Staff shell: caseload chat + a clinician dashboard (sobriety monitoring,
    /// announcements, meetings, moderation, flags) + community + profile.
    /// No sobriety tracker / "recovery journey" — this is the clinician view.
    private var staffTabView: some View {
        TabView(selection: $appViewModel.selectedTab) {
            Tab("Clients", systemImage: "person.2.fill", value: .chat) {
                StaffClientsScreen()
            }

            // Clinician dashboard — reuses the admin dashboard, scoped by role to
            // the staff sections (sobriety, moderation, meetings, chat monitor,
            // announcements, flags). No user-approval / user-management.
            Tab("Care Tools", systemImage: "square.grid.2x2.fill", value: .home) {
                AdminDashboardScreen()
            }

            // Telehealth scheduling console — pending requests, agenda, and
            // one-tap scheduling with any client on the caseload.
            Tab("Schedule", systemImage: "calendar.badge.clock", value: .care) {
                StaffScheduleScreen()
            }

            Tab("Community", systemImage: "bubble.left.and.bubble.right.fill", value: .community) {
                CommunityScreen()
            }

            Tab("Profile", systemImage: "person.circle.fill", value: .profile) {
                if let user = appViewModel.currentUser {
                    NavigationStack {
                        ProfileScreen(user: user)
                    }
                }
            }
        }
        .tint(AppTheme.accent)
    }

    private var alumniTabView: some View {
        TabView(selection: $appViewModel.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                if appViewModel.isStrugglingMode {
                    StrugglingModeLockedView()
                } else {
                    HomeScreen()
                }
            }

            Tab("Community", systemImage: "person.2.fill", value: .community) {
                if appViewModel.isStrugglingMode {
                    StrugglingModeLockedView()
                } else {
                    CommunityScreen()
                }
            }

            Tab("Meetings", systemImage: "calendar", value: .meetings) {
                if appViewModel.isStrugglingMode {
                    StrugglingModeLockedView()
                } else {
                    MeetingsScreen()
                }
            }

            Tab("Chat", systemImage: "message.fill", value: .chat) {
                ChatListScreen()
            }

            Tab("Profile", systemImage: "person.circle.fill", value: .profile) {
                if appViewModel.isStrugglingMode {
                    StrugglingModeLockedView()
                } else {
                    if let user = appViewModel.currentUser {
                        NavigationStack {
                            ProfileScreen(user: user)
                        }
                    }
                }
            }
        }
        .tint(AppTheme.accent)
        .overlay(alignment: .bottom) {
            // Floating "Back to Admin" button when viewing as user
            if appViewModel.isViewingAsUser {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        appViewModel.isViewingAsUser = false
                        appViewModel.selectedTab = .home
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.circle.fill")
                        Text("Back to Admin")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 60)
            }
        }
    }
}
