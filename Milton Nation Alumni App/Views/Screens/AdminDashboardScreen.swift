import SwiftUI
import PhotosUI

struct AdminDashboardScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(AdminViewModel.self) private var viewModel
    @State private var staffPhotoItem: PhotosPickerItem?

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    statsRow
                    sectionGrid

                    // Expanded section content
                    if let section = viewModel.activeSection {
                        expandedSectionContent(section)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer(minLength: 32)
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.activeSection)
            }
            .background(AppTheme.background)
            .onAppear {
                // Set facility filter so admins only see their own facility's data
                if appViewModel.currentUser?.role.isSuperAdmin == true {
                    viewModel.adminFacilityFilter = appViewModel.activeFacility
                } else {
                    viewModel.adminFacilityFilter = appViewModel.currentUser?.adminFacility
                }
                viewModel.loadData()
                viewModel.subscribeToAdminPostUpdates()
            }
            .onDisappear {
                viewModel.unsubscribeFromAdminPostUpdates()
            }
            .onChange(of: appViewModel.activeFacility) { _, newFacility in
                // Super admin switched facility — reload with new filter
                if appViewModel.currentUser?.role.isSuperAdmin == true {
                    viewModel.adminFacilityFilter = newFacility
                    viewModel.loadData()
                }
            }
            .sheet(isPresented: $viewModel.showingContentEditor) {
                contentEditorSheet
            }
            .sheet(isPresented: $viewModel.showingMeetingEditor) {
                meetingEditorSheet
            }
            .sheet(isPresented: $viewModel.showingAnnouncementEditor) {
                announcementEditorSheet
            }
            .sheet(isPresented: $viewModel.showModerationModal) {
                chatModerationSheet
            }
            .sheet(isPresented: $viewModel.showRSVPSheet) {
                rsvpListSheet
            }
            .photosPicker(isPresented: $viewModel.showStaffPhotoPicker, selection: $staffPhotoItem, matching: .images)
            .onChange(of: staffPhotoItem) {
                Task {
                    if let data = try? await staffPhotoItem?.loadTransferable(type: Data.self),
                       UIImage(data: data) != nil,
                       let staffId = viewModel.staffPhotoUploadId {
                        await viewModel.uploadStaffPhoto(data: data, staffId: staffId)
                    }
                    staffPhotoItem = nil
                }
            }
            .alert("Promote User", isPresented: $viewModel.showPromoteConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelPromotion()
                }
                Button("Promote to Admin") {
                    viewModel.selectedPromotionRole = .admin
                    viewModel.confirmPromoteUser()
                }
                Button("Promote to Super Admin") {
                    viewModel.selectedPromotionRole = .superAdmin
                    viewModel.confirmPromoteUser()
                }
            } message: {
                if let user = viewModel.userToPromote {
                    Text("Choose a role for \(user.fullName).\n\nAdmin: Community Moderation, Staff Assignments, Sobriety Tracking, Meeting Management, Chat Monitoring.\n\nSuper Admin: Full unrestricted access to all sections.")
                }
            }
            .overlay {
                ToastNotification(
                    icon: "trophy.fill",
                    message: viewModel.badgeToastMessage,
                    isShowing: $viewModel.showBadgeToast
                )
            }
        }
    }

    // MARK: - Header (MiltonLogoView + Logout)

    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                MiltonLogoView(size: .small)
                HStack {
                    // View as User button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            appViewModel.isViewingAsUser = true
                            appViewModel.selectedTab = .home
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                            Text("User View")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(.white)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                    }
                    Spacer()
                    Button {
                        appViewModel.logout()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(AppTheme.cardBackground)

            // Brand gradient bar
            HStack(spacing: 0) {
                ForEach(0..<AppTheme.brandPalette.count, id: \.self) { i in
                    Rectangle()
                        .fill(AppTheme.brandPalette[i])
                        .frame(height: 3)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Admin Dashboard")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    if let user = appViewModel.currentUser {
                        Text("Welcome back, \(user.firstName)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let user = appViewModel.currentUser {
                        Text(user.role.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                    // Facility badge + switch button (visible to all admins)
                    Button {
                        if appViewModel.currentUser?.role.isSuperAdmin == true {
                            appViewModel.showFacilityPicker = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(appViewModel.activeFacility.emoji)
                            Text(appViewModel.activeFacility.displayName)
                                .font(.caption.bold())
                            if appViewModel.currentUser?.role.isSuperAdmin == true {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(AppTheme.accent)
                        .background(AppTheme.accent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .disabled(appViewModel.currentUser?.role.isSuperAdmin != true)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(title: "New Users", count: viewModel.pendingUsers.count, icon: "person.badge.clock", color: AppTheme.struggling)
            statCard(title: "Posts", count: viewModel.pendingPosts.count, icon: "clock.fill", color: AppTheme.strugglesColor)
            statCard(title: "Alumni", count: viewModel.alumniUsers.count, icon: "person.2.fill", color: AppTheme.accent)
            notificationStatCard
        }
        .padding(.horizontal)
    }

    private func statCard(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardStyle()
    }

    private var notificationStatCard: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.callout)
                    .foregroundStyle(AppTheme.struggling)
                if viewModel.unreadNotificationCount > 0 {
                    Text("\(viewModel.unreadNotificationCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(AppTheme.struggling)
                        .clipShape(Circle())
                        .offset(x: 8, y: -6)
                }
            }
            Text("\(viewModel.sobrietyNotifications.count)")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Alerts")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardStyle()
    }

    // MARK: - Section Grid

    private var sectionGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        let userRole = appViewModel.currentUser?.role ?? .alumni
        var availableSections = AdminViewModel.AdminSection.sections(for: userRole)

        // Super Admin: hide sobriety tracker from dashboard (alumni still see it on their side)
        if userRole.isSuperAdmin {
            availableSections.removeAll { $0 == .sobriety }
        }

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(availableSections, id: \.rawValue) { section in
                sectionButton(section)
            }
        }
        .padding(.horizontal)
    }

    private func sectionButton(_ section: AdminViewModel.AdminSection) -> some View {
        let isActive = viewModel.activeSection == section
        let badgeCount = badgeForSection(section)

        return Button {
            withAnimation {
                viewModel.activeSection = isActive ? nil : section
            }
        } label: {
            HStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: section.icon)
                        .font(.body)
                        .foregroundStyle(isActive ? .white : section.color)
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(AppTheme.struggling)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
                Text(section.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(isActive ? .white : AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: isActive ? "chevron.up" : "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(isActive ? .white.opacity(0.7) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(isActive ? section.color : AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            .shadow(color: .black.opacity(isActive ? 0.1 : 0.04), radius: isActive ? 4 : 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func badgeForSection(_ section: AdminViewModel.AdminSection) -> Int {
        switch section {
        case .pendingApprovals: return viewModel.unreadPendingUserCount
        case .sobriety: return viewModel.unreadNotificationCount
        case .moderation: return viewModel.pendingPosts.count
        case .chatMonitor: return viewModel.chatMonitorEntries.filter { $0.flagged }.count
        case .inviteAlumni: return 0
        case .contentFlags: return viewModel.pendingFlagCount
        default: return 0
        }
    }

    // MARK: - Expanded Section Content

    @ViewBuilder
    private func expandedSectionContent(_ section: AdminViewModel.AdminSection) -> some View {
        switch section {
        case .pendingApprovals:
            pendingApprovalsSection
        case .inviteAlumni:
            inviteAlumniSection
        case .sobriety:
            sobrietyTrackingSection
        case .assignments:
            staffAssignmentSection
        case .content:
            contentManagementSection
        case .moderation:
            communityModerationSection
        case .contacts:
            contactManagementSection
        case .chatMonitor:
            chatMonitoringSection
        case .meetingMgmt:
            meetingManagementSection
        case .userManagement:
            userManagementSection
        case .gamification:
            gamificationSection
        case .announcements:
            announcementsSection
        case .contentFlags:
            contentFlagsSection
        case .emergencyAccess:
            emergencyAccessSection
        }
    }

    // MARK: - 0. Pending User Approvals Section

    private var pendingApprovalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.clock.fill")
                    .foregroundStyle(AppTheme.struggling)
                Text("Pending User Approvals")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(viewModel.pendingUsers.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.struggling.opacity(0.15))
                    .foregroundStyle(AppTheme.struggling)
                    .clipShape(Capsule())
            }

            if viewModel.pendingUsers.isEmpty {
                emptyState(icon: "checkmark.circle", message: "No pending registrations")
            } else {
                ForEach(viewModel.pendingUsers) { user in
                    pendingUserCard(user)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func pendingUserCard(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AppTheme.struggling.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill.questionmark")
                            .font(.callout)
                            .foregroundStyle(AppTheme.struggling)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.fullName)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(user.email)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("PENDING")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.struggling.opacity(0.15))
                    .foregroundStyle(AppTheme.struggling)
                    .clipShape(Capsule())
            }

            // User details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Label(user.recoveryProgram, systemImage: "building.2.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Label("\(user.daysOfRecovery) days sober", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.accentSage)
                }
                Label("Registered \(user.createdAt, style: .relative) ago", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Facility assignment picker
            VStack(alignment: .leading, spacing: 6) {
                Text("ASSIGN TO FACILITY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(Facility.allCases) { facility in
                        let isSelected = viewModel.effectiveFacility(for: user) == facility
                        Button {
                            viewModel.facilityOverrides[user.id] = facility
                        } label: {
                            HStack(spacing: 4) {
                                Text(facility.emoji)
                                Text(facility.displayName)
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                            .background(isSelected ? AppTheme.accent : AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? AppTheme.accent : AppTheme.divider, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    viewModel.approvePendingUser(userId: user.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(AppTheme.accentSage)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    viewModel.rejectPendingUser(userId: user.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(AppTheme.struggling)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Invite Alumni Section

    private var inviteAlumniSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(AppTheme.primary)
                Text("Send Invite SMS")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Name field (optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Name (optional)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("e.g. John", text: $viewModel.inviteName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }

            // Phone field
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("e.g. (555) 123-4567", text: $viewModel.invitePhone)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            // Send button
            Button {
                viewModel.sendInvite()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.inviteSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(viewModel.inviteSending ? "Sending..." : "Send Invite")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(viewModel.invitePhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.inviteSending ? AppTheme.textSecondary : AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.invitePhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.inviteSending)

            // Success message
            if let success = viewModel.inviteSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(success)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Error message
            if let error = viewModel.inviteError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Info note
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Sends a branded SMS invite with a link to download the Milton Alumni app.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - 1. Sobriety Tracking Section

    private var sobrietyTrackingSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 12) {
            // Notifications sub-section
            if !viewModel.sobrietyNotifications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(AppTheme.struggling)
                        Text("Sobriety Date Changes")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if viewModel.unreadNotificationCount > 0 {
                            Button("Mark All Read") {
                                viewModel.markAllNotificationsRead()
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        }
                    }

                    ForEach(viewModel.sobrietyNotifications) { notification in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(notification.isRead ? AppTheme.textSecondary.opacity(0.2) : AppTheme.struggling)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(notification.user.fullName)
                                        .font(.caption.bold())
                                        .foregroundStyle(AppTheme.textPrimary)
                                    if notification.wasReset {
                                        Text("RESET")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(AppTheme.struggling.opacity(0.15))
                                            .foregroundStyle(AppTheme.struggling)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text("Changed: \(notification.previousDate.formatted(date: .abbreviated, time: .omitted)) -> \(notification.newDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(notification.changedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(8)
                        .background(notification.isRead ? AppTheme.background : AppTheme.struggling.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            viewModel.markNotificationRead(notification.id)
                        }
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)
            }

            // Alumni sobriety list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(AppTheme.accentMedium)
                    Text("All Alumni Sobriety Dates")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(viewModel.alumniUsers.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.accent.opacity(0.15))
                        .foregroundStyle(AppTheme.accent)
                        .clipShape(Capsule())
                }

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Search alumni...", text: $viewModel.sobrietySearchText)
                        .font(.subheadline)
                }
                .padding(8)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                ForEach(viewModel.filteredAlumni) { user in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(sobrietyColor(days: user.daysOfRecovery).opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("\(user.daysOfRecovery)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(sobrietyColor(days: user.daysOfRecovery))
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Sobriety: \(user.sobrietyDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(user.daysOfRecovery) days")
                                .font(.caption.bold())
                                .foregroundStyle(sobrietyColor(days: user.daysOfRecovery))
                            Text(user.status.rawValue.capitalized)
                                .font(.system(size: 9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(user.status == .active ? AppTheme.accentSage.opacity(0.15) : AppTheme.background)
                                .foregroundStyle(user.status == .active ? .green : AppTheme.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)

                    if user.id != viewModel.filteredAlumni.last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)
        }
    }

    private func sobrietyColor(days: Int) -> Color {
        switch days {
        case ..<30: return AppTheme.struggling
        case 30..<90: return AppTheme.strugglesColor
        case 90..<365: return AppTheme.accentSage
        default: return AppTheme.accent
        }
    }

    // MARK: - 2. Staff Assignment Section

    private var staffAssignmentSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .foregroundStyle(AppTheme.primaryMedium)
                Text("Therapist / Case Manager Assignment")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            // Add Staff Member
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(AppTheme.accent)
                    Text("Add Staff Member")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                }

                TextField("Staff Name", text: $viewModel.newStaffName)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)

                Picker("Role", selection: $viewModel.newStaffRole) {
                    Text("Case Manager").tag(UserRole.caseManager)
                    Text("Therapist").tag(UserRole.therapist)
                }
                .pickerStyle(.segmented)

                Button {
                    viewModel.addStaffMember(name: viewModel.newStaffName, role: viewModel.newStaffRole)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Staff")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(viewModel.newStaffName.trimmingCharacters(in: .whitespaces).isEmpty
                        ? AppTheme.textSecondary : AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(viewModel.newStaffName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(10)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Current Staff Roster
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text("Current Staff (\(viewModel.staffMembers.count))")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ForEach(viewModel.staffMembers) { staff in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(staff.fullName)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(staff.role.displayName)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            viewModel.beginPhotoUpload(for: staff.id)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: staff.profilePhotoURL != nil ? "arrow.triangle.2.circlepath.camera" : "camera.badge.ellipsis")
                                    .font(.caption2)
                                Text(staff.profilePhotoURL != nil ? "Replace" : "Upload")
                                    .font(.caption2.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundStyle(AppTheme.accent)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(10)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Divider()

            // Alumni assignments — 3 role-based pickers per user
            ForEach(viewModel.alumniUsers) { alumni in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(alumni.fullName)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(alumni.email)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }

                    // 2 role-based pickers (Counselor removed from care team)
                    staffRolePicker(alumniId: alumni.id, role: .caseManager, label: "Case Manager")
                    staffRolePicker(alumniId: alumni.id, role: .therapist, label: "Therapist")
                }
                .padding(10)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func staffRolePicker(alumniId: UUID, role: UserRole, label: String) -> some View {
        let staffForRole = viewModel.staffMembers.filter { $0.role == role }
        let assigned = viewModel.assignedStaffMember(for: alumniId, role: role)

        return HStack(spacing: 8) {
            Text("\(label):")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 90, alignment: .leading)

            Menu {
                Button("Unassigned") {
                    viewModel.assignStaff(alumniId: alumniId, role: role, staffId: nil)
                }
                ForEach(staffForRole) { staff in
                    Button(staff.fullName) {
                        viewModel.assignStaff(alumniId: alumniId, role: role, staffId: staff.id)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let assigned {
                        Text(assigned.fullName)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.accent)
                    } else {
                        Text("Unassigned")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.accent.opacity(0.08))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - 3. Content Management Section

    private var contentManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(AppTheme.accentLight)
                Text("Reflections / News / Pinned Updates")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.beginCreateContent()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accent)
                }
            }

            if viewModel.contentItems.isEmpty {
                emptyState(icon: "doc.text", message: "No content items yet")
            } else {
                ForEach(viewModel.contentItems) { item in
                    contentItemRow(item)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func contentItemRow(_ item: AdminContentItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: item.type.iconName)
                    .font(.caption)
                    .foregroundStyle(item.type.color)
                Text(item.type.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(item.type.color)
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.accentSage)
                }
                Spacer()
                Text(item.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(item.title)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(item.body)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Button {
                    viewModel.beginEditContent(item)
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                Button {
                    viewModel.toggleContentPin(item)
                } label: {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accentSage)
                }
                Spacer()
                Button {
                    viewModel.deleteContent(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.struggling)
                }
            }
        }
        .padding(10)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 4. Community Moderation Section (existing, integrated)

    private var communityModerationSection: some View {
        VStack(spacing: 12) {
            // Pending Posts
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .foregroundStyle(AppTheme.strugglesColor)
                    Text("Pending Posts")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(viewModel.pendingPosts.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.strugglesColor.opacity(0.15))
                        .foregroundStyle(AppTheme.strugglesColor)
                        .clipShape(Capsule())
                }

                if viewModel.pendingPosts.isEmpty {
                    emptyState(icon: "checkmark.circle", message: "No pending posts")
                } else {
                    ForEach(viewModel.pendingPosts) { post in
                        pendingPostCard(post: post)
                    }
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)

            // Approved Posts
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentSage)
                    Text("Approved Posts")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }

                if viewModel.approvedPosts.isEmpty {
                    emptyState(icon: "doc.text", message: "No approved posts yet")
                } else {
                    ForEach(viewModel.approvedPosts) { post in
                        approvedPostCard(post: post)
                    }
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)
        }
    }

    // MARK: - 5. Contact Management Section

    private var contactManagementSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "phone.circle.fill")
                    .foregroundStyle(AppTheme.accentSage)
                Text("Editable Contact Numbers")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.addNewContact()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accent)
                }
            }

            // Company Contacts
            VStack(alignment: .leading, spacing: 6) {
                Text("Company Contacts")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(viewModel.companyContacts) { contact in
                    if viewModel.editingContactId == contact.id {
                        // Edit mode
                        VStack(spacing: 8) {
                            TextField("Name", text: $viewModel.contactEditName)
                                .font(.caption)
                                .textFieldStyle(.roundedBorder)
                            TextField("Phone", text: $viewModel.contactEditPhone)
                                .font(.caption)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                            TextField("Role", text: $viewModel.contactEditRole)
                                .font(.caption)
                                .textFieldStyle(.roundedBorder)
                            HStack {
                                Button("Save") {
                                    viewModel.saveContact()
                                }
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.accent)
                                .clipShape(Capsule())

                                Button("Cancel") {
                                    viewModel.cancelEditContact()
                                }
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSecondary)

                                Spacer()
                            }
                        }
                        .padding(10)
                        .background(AppTheme.accent.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Display mode
                        HStack(spacing: 10) {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                // Tappable phone number — opens native Phone app
                                Button {
                                    PhoneService.call(contact.phoneNumber)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(contact.phoneNumber)
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.accent)
                                        Image(systemName: "phone.fill")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Call \(contact.name) at \(contact.phoneNumber)")
                                if let role = contact.role {
                                    Text(role)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                            Spacer()
                            Button {
                                viewModel.beginEditContact(contact)
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Button {
                                viewModel.deleteContact(contact)
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundStyle(AppTheme.struggling.opacity(0.6))
                            }
                        }
                        .padding(8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Crisis Resources (read-only display)
            VStack(alignment: .leading, spacing: 6) {
                Text("Crisis Resources")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(viewModel.crisisResources) { resource in
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.struggling)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.name)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            // Tappable phone number — opens native Phone app
                            Button {
                                PhoneService.call(resource.phoneNumber)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(resource.phoneNumber)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.struggling)
                                    Image(systemName: "phone.fill")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.struggling)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Call \(resource.name) at \(resource.phoneNumber)")
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(AppTheme.strugglingLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - 6. Chat Monitoring Section

    private var chatMonitoringSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Chat Monitoring")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                let flaggedCount = viewModel.chatMonitorEntries.filter { $0.flagged }.count
                if flaggedCount > 0 {
                    Text("\(flaggedCount) flagged")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.struggling.opacity(0.15))
                        .foregroundStyle(AppTheme.struggling)
                        .clipShape(Capsule())
                }
            }

            // Flagged-only toggle
            Toggle(isOn: $viewModel.showFlaggedChatOnly) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.struggling)
                    Text("Show flagged only")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .toggleStyle(.switch)
            .tint(AppTheme.struggling)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Search conversations...", text: $viewModel.chatSearchText)
                    .font(.subheadline)
            }
            .padding(8)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if viewModel.filteredChatEntries.isEmpty {
                emptyState(icon: "message", message: "No conversations to monitor")
            } else {
                ForEach(viewModel.filteredChatEntries) { entry in
                    chatMonitorRow(entry)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func chatMonitorRow(_ entry: ChatMonitorEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if entry.flagged || entry.moderationStatus == .denied {
                    Image(systemName: entry.moderationStatus == .denied ? "xmark.circle.fill" : "flag.fill")
                        .font(.caption)
                        .foregroundStyle(entry.moderationStatus == .denied ? .gray : AppTheme.struggling)
                } else if entry.moderationStatus == .allowed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentSage)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.alumniName)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    HStack(spacing: 4) {
                        Text("with")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(entry.staffName)
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.accent)
                        Text("(\(entry.staffRole.displayName))")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.lastMessageAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(entry.messageCount) msgs")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(AppTheme.accent.opacity(0.1))
                        .foregroundStyle(AppTheme.accent)
                        .clipShape(Capsule())
                }
            }

            Text(entry.lastMessagePreview)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .italic()

            // Moderation status badge
            if entry.moderationStatus == .allowed {
                Text("✓ Allowed")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.accentSage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.accentSage.opacity(0.1))
                    .clipShape(Capsule())
            } else if entry.moderationStatus == .denied {
                Text("✗ Denied / Removed")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.textSecondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Allow/Deny actions for flagged messages awaiting review
            if entry.moderationStatus == .flagged {
                HStack(spacing: 10) {
                    Button {
                        viewModel.beginModeration(entry)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.circle.fill")
                            Text("Review")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }

                    Button {
                        viewModel.allowFlaggedMessage(entry.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            Text("Allow")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentSage)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }

                    Button {
                        viewModel.denyFlaggedMessage(entry.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Deny")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.struggling)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }

                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            entry.moderationStatus == .flagged ? AppTheme.struggling.opacity(0.04) :
            entry.moderationStatus == .denied ? AppTheme.textSecondary.opacity(0.04) :
            AppTheme.background
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    entry.moderationStatus == .flagged ? AppTheme.struggling.opacity(0.3) :
                    entry.moderationStatus == .denied ? AppTheme.textSecondary.opacity(0.3) :
                    .clear,
                    lineWidth: 1
                )
        )
    }

    // MARK: - 7. Meeting Management Section

    private var meetingManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundStyle(AppTheme.accentSage)
                Text("Meeting Management")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.beginCreateMeeting()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accent)
                }
            }

            if viewModel.meetings.isEmpty {
                emptyState(icon: "calendar", message: "No meetings scheduled")
            } else {
                ForEach(viewModel.meetings) { meeting in
                    meetingManagementRow(meeting)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func meetingManagementRow(_ meeting: Meeting) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: meeting.meetingType.iconName)
                    .font(.caption)
                    .foregroundStyle(meetingTypeColor(meeting.meetingType))
                Text(meeting.title)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Text(meeting.meetingType.displayName)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(meetingTypeColor(meeting.meetingType).opacity(0.12))
                .foregroundStyle(meetingTypeColor(meeting.meetingType))
                .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Label(meeting.formattedDate, systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                Label(meeting.formattedTimeRange, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let address = meeting.locationAddress {
                Label(address, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.accent)
                    .lineLimit(1)
            }

            if meeting.isRecurring {
                Label(meeting.recurrencePattern?.rawValue.capitalized ?? "Recurring", systemImage: "repeat")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.accentSage)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.beginEditMeeting(meeting)
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                Button {
                    viewModel.selectedRSVPMeeting = meeting
                    viewModel.showRSVPSheet = true
                } label: {
                    Label("RSVPs (\(meeting.rsvpUserIds.count))", systemImage: "person.2.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accentSage)
                }
                Spacer()
                Button {
                    viewModel.deleteMeeting(meeting)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.struggling)
                }
            }
        }
        .padding(10)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func meetingTypeColor(_ type: MeetingType) -> Color {
        switch type {
        case .inPerson: return AppTheme.accent
        case .virtual: return AppTheme.accentMedium
        case .hybrid: return AppTheme.accentSage
        }
    }

    // MARK: - RSVP List Sheet

    private var rsvpListSheet: some View {
        NavigationStack {
            Group {
                if let meeting = viewModel.selectedRSVPMeeting {
                    let users = viewModel.rsvpUsers(for: meeting)
                    if users.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                            Text("No RSVPs yet")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                        }
                    } else {
                        List(users) { user in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Text(String(user.fullName.prefix(1)))
                                            .font(.caption.bold())
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.fullName)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(user.username)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accentSage)
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.selectedRSVPMeeting?.title ?? "RSVPs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showRSVPSheet = false
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let meeting = viewModel.selectedRSVPMeeting {
                        Text("\(meeting.rsvpUserIds.count) attendees")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - 8. Gamification Section (Super Admin)

    private var gamificationSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 12) {
            // Badge earned notifications
            if !viewModel.badgeNotifications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(AppTheme.accentLime)
                        Text("Badge Earned Alerts")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if viewModel.unreadBadgeNotificationCount > 0 {
                            Text("\(viewModel.unreadBadgeNotificationCount) new")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppTheme.accentLime.opacity(0.15))
                                .foregroundStyle(AppTheme.accentLime)
                                .clipShape(Capsule())
                        }
                    }

                    ForEach(viewModel.badgeNotifications) { notification in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(notification.isRead ? AppTheme.textSecondary.opacity(0.2) : AppTheme.accentLime)
                                .frame(width: 8, height: 8)

                            Text(notification.badge.emoji)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(notification.user.fullName)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Earned \(notification.badge.name) badge (\(notification.badge.pointsRequired) pts)")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(notification.earnedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(8)
                        .background(notification.isRead ? AppTheme.background : AppTheme.accentLime.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            viewModel.markBadgeNotificationRead(notification.id)
                        }
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)
            }

            // Point Values
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(AppTheme.accentLime)
                    Text("Point Values")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("Max Goal: 5,000")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }

                ForEach(PointAction.allCases, id: \.rawValue) { action in
                    HStack {
                        Text(action.displayName)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("+\(action.points) pts")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)

            // Editable Badges
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "rosette")
                        .foregroundStyle(AppTheme.accentLime)
                    Text("Badge Library")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(viewModel.editableBadges.count) badges")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ForEach(viewModel.editableBadges) { badge in
                    HStack(spacing: 10) {
                        Text(badge.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(badge.name)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(badge.description)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(badge.pointsRequired) pts")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.accent)
                        Button {
                            viewModel.beginEditBadge(badge)
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)
        }
        .sheet(isPresented: $viewModel.showingBadgeEditor) {
            badgeEditorSheet
        }
    }

    private var badgeEditorSheet: some View {
        @Bindable var viewModel = viewModel
        return NavigationStack {
            Form {
                Section("Badge Details") {
                    TextField("Name", text: $viewModel.badgeEditorName)
                    TextField("Description", text: $viewModel.badgeEditorDescription)
                    TextField("Emoji", text: $viewModel.badgeEditorEmoji)
                    HStack {
                        Text("Points Required")
                        Spacer()
                        TextField("Points", value: $viewModel.badgeEditorPoints, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Edit Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelBadgeEdit()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveBadgeEdit()
                    }
                    .disabled(viewModel.badgeEditorName.isEmpty)
                }
            }
        }
    }

    // MARK: - Content Editor Sheet

    private var contentEditorSheet: some View {
        @Bindable var viewModel = viewModel
        return NavigationStack {
            Form {
                Section("Content Type") {
                    Picker("Type", selection: $viewModel.contentEditorType) {
                        ForEach(AdminContentItem.ContentType.allCases, id: \.rawValue) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Content") {
                    TextField("Title", text: $viewModel.contentEditorTitle)
                    TextEditor(text: $viewModel.contentEditorBody)
                        .frame(minHeight: 100)
                }

                Section {
                    Toggle("Pinned", isOn: $viewModel.contentEditorIsPinned)
                }
            }
            .navigationTitle(viewModel.editingContentItem == nil ? "New Content" : "Edit Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingContentEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveContent()
                    }
                    .disabled(viewModel.contentEditorTitle.isEmpty || viewModel.contentEditorBody.isEmpty)
                }
            }
        }
    }

    // MARK: - Meeting Editor Sheet

    private var meetingEditorSheet: some View {
        @Bindable var viewModel = viewModel
        return NavigationStack {
            Form {
                Section("Meeting Info") {
                    TextField("Title", text: $viewModel.meetingTitle)
                    TextField("Description (optional)", text: $viewModel.meetingDescription)

                    Picker("Type", selection: $viewModel.meetingType) {
                        ForEach(MeetingType.allCases, id: \.rawValue) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Date & Time") {
                    DatePicker("Date", selection: $viewModel.meetingDate, displayedComponents: .date)
                    DatePicker("Start Time", selection: $viewModel.meetingStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $viewModel.meetingEndTime, displayedComponents: .hourAndMinute)
                }

                Section("Location") {
                    if viewModel.meetingType != .virtual {
                        TextField("Address", text: $viewModel.meetingLocation)
                    }
                    if viewModel.meetingType != .inPerson {
                        TextField("Virtual Link", text: $viewModel.meetingVirtualLink)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Recurrence") {
                    Toggle("Recurring", isOn: $viewModel.meetingIsRecurring)
                    if viewModel.meetingIsRecurring {
                        Picker("Pattern", selection: $viewModel.meetingRecurrence) {
                            ForEach(RecurrencePattern.allCases, id: \.rawValue) { pattern in
                                Text(pattern.rawValue.capitalized).tag(pattern)
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.editingMeeting == nil ? "New Meeting" : "Edit Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingMeetingEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveMeeting()
                    }
                    .disabled(viewModel.meetingTitle.isEmpty)
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func pendingPostCard(post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.userName)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                // Show moderation status badge
                if post.status == .flaggedForCrisis {
                    Text("CRISIS")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.struggling)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                } else if post.status == .pendingReview {
                    Text("FLAGGED")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.strugglesColor.opacity(0.15))
                        .foregroundStyle(AppTheme.strugglesColor)
                        .clipShape(Capsule())
                }
                Text(post.category.emoji + " " + post.category.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.background)
                    .clipShape(Capsule())
            }

            // Show matched keywords if any
            if !post.matchedKeywords.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.struggling)
                    Text("Keywords: \(post.matchedKeywords.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.struggling)
                        .lineLimit(1)
                }
            }

            Text(post.content)
                .font(.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3)

            // Media preview
            if post.mediaURL != nil {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(post.mediaType == .video ? AppTheme.accentMedium.opacity(0.08) : AppTheme.accent.opacity(0.08))
                        .frame(height: 120)
                    VStack(spacing: 6) {
                        Image(systemName: post.mediaType == .video ? "video.fill" : "photo.fill")
                            .font(.title2)
                            .foregroundStyle(post.mediaType == .video ? AppTheme.accentMedium.opacity(0.5) : AppTheme.accent.opacity(0.5))
                        Text(post.mediaType == .video ? "Video Attachment" : "Image Attachment")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            Text(post.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 10) {
                Button {
                    viewModel.moderatePost(postId: post.id, action: .approved)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Approve")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentSage)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }

                Button {
                    viewModel.moderatePost(postId: post.id, action: .rejected)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppTheme.struggling)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
        .padding(10)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func approvedPostCard(post: CommunityPost) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.userName)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(post.content)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                if post.mediaURL != nil {
                    HStack(spacing: 4) {
                        Image(systemName: post.mediaType == .video ? "video.fill" : "photo.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.accent)
                        Text(post.mediaType == .video ? "Video" : "Image")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            Spacer()
            Button {
                viewModel.togglePin(postId: post.id)
            } label: {
                Image(systemName: post.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(post.isPinned ? AppTheme.accent : AppTheme.textSecondary)
                    .padding(6)
                    .background(post.isPinned ? AppTheme.accent.opacity(0.1) : AppTheme.background)
                    .clipShape(Circle())
            }
        }
        .padding(10)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Chat Moderation Sheet

    private var chatModerationSheet: some View {
        NavigationStack {
            if let entry = viewModel.moderatingEntry {
                VStack(spacing: 20) {
                    // Flagged message details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(AppTheme.struggling)
                            Text("Flagged Conversation")
                                .font(.headline.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Alumni:")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(entry.alumniName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            HStack {
                                Text("Staff:")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("\(entry.staffName) (\(entry.staffRole.displayName))")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.accent)
                            }
                            HStack {
                                Text("Messages:")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("\(entry.messageCount)")
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Flagged Message:")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSecondary)

                        Text("\"\(entry.lastMessagePreview)\"")
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.struggling.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.struggling.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding()

                    Spacer()

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            viewModel.allowFlaggedMessage(entry.id)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Allow — Dismiss Flag")
                            }
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentSage)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            viewModel.denyFlaggedMessage(entry.id)
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Deny — Remove Message")
                            }
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.struggling)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
                .navigationTitle("Review Flagged Message")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.showModerationModal = false
                            viewModel.moderatingEntry = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - 9. User Management Section (Super Admin)

    private var userManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.key.fill")
                    .foregroundStyle(AppTheme.primaryMedium)
                Text("User Management")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(viewModel.alumniUsers.count) users")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text("Promote users to Admin or Super Admin. Admins access: Moderation, Staff, Sobriety, Meetings, Chat. Super Admins have full unrestricted access.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.bottom, 4)

            ForEach(viewModel.alumniUsers) { user in
                HStack(spacing: 10) {
                    Circle()
                        .fill(roleColor(user.role).opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: userRoleIcon(user.role))
                                .font(.caption)
                                .foregroundStyle(roleColor(user.role))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullName)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(user.email)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    // Role badge
                    Text(user.role.displayName)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(roleColor(user.role).opacity(0.15))
                        .foregroundStyle(roleColor(user.role))
                        .clipShape(Capsule())

                    // Promote button (for alumni and admins — Super Admins are already max)
                    if user.role == .alumni || user.role == .admin {
                        Button {
                            viewModel.beginPromoteUser(user)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.caption2)
                                Text(user.role == .admin ? "Upgrade" : "Promote")
                                    .font(.caption2.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundStyle(.white)
                            .background(user.role == .admin ? AppTheme.primary : AppTheme.primaryMedium)
                            .clipShape(Capsule())
                        }
                    } else if user.role == .superAdmin {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                .padding(10)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func userRoleIcon(_ role: UserRole) -> String {
        switch role {
        case .superAdmin: return "crown.fill"
        case .admin: return "person.badge.key"
        default: return "person.fill"
        }
    }

    private func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .alumni: return AppTheme.accent
        case .admin: return AppTheme.primaryMedium
        case .superAdmin: return AppTheme.primary
        case .caseManager, .therapist, .counselor: return AppTheme.accentSage
        }
    }

    // MARK: - 10. Announcements Section (Super Admin)

    private var announcementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Announcements")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.beginCreateAnnouncement()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accent)
                }
            }

            Text("Announcements appear in the \"Updates & News\" section on the alumni homepage.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            if viewModel.announcements.isEmpty {
                emptyState(icon: "megaphone", message: "No announcements yet")
            } else {
                ForEach(viewModel.announcements) { announcement in
                    announcementRow(announcement)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
    }

    private func announcementRow(_ item: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "megaphone.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
                Text(item.title)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(item.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(item.description)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)

            HStack(spacing: 12) {
                Button {
                    viewModel.beginEditAnnouncement(item)
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                Button {
                    viewModel.deleteAnnouncement(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.struggling)
                }
            }
        }
        .padding(10)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var announcementEditorSheet: some View {
        @Bindable var viewModel = viewModel
        return NavigationStack {
            Form {
                Section("Announcement") {
                    TextField("Title", text: $viewModel.announcementEditorTitle)
                    TextEditor(text: $viewModel.announcementEditorDescription)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(viewModel.editingAnnouncement == nil ? "New Announcement" : "Edit Announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingAnnouncementEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveAnnouncement()
                    }
                    .disabled(viewModel.announcementEditorTitle.isEmpty || viewModel.announcementEditorDescription.isEmpty)
                }
            }
        }
    }

    // MARK: - 12. Content Flags Section

    private var contentFlagsSection: some View {
        ContentFlagsAdminView(viewModel: viewModel)
            .onAppear { viewModel.loadContentFlags() }
    }

    // MARK: - Reusable Helpers

    private func emptyState(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.vertical, 16)
            Spacer()
        }
    }

    // MARK: - Emergency Access (Break-Glass) Section

    private var emergencyAccessSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 16) {

            // Warning banner
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Access Only")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                    Text("Every action is permanently logged and the user is notified. Use only in genuine emergencies (crisis, safety risk, unresponsive user).")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(12)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Grant new access
            VStack(alignment: .leading, spacing: 10) {
                Text("Grant Emergency Access")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                // User picker
                Menu {
                    ForEach(viewModel.allUsers.filter { $0.role != UserRole.admin && $0.role != UserRole.superAdmin }) { user in
                        Button(user.fullName) {
                            viewModel.breakGlassTargetUser = user
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.breakGlassTargetUser?.fullName ?? "Select user…")
                            .foregroundStyle(viewModel.breakGlassTargetUser == nil ? AppTheme.textSecondary : AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(10)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Reason input
                TextField("Reason for access (required)…", text: $viewModel.emergencyAccessReason, axis: .vertical)
                    .font(.subheadline)
                    .padding(10)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(2...4)

                if let err = viewModel.emergencyAccessError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    viewModel.showBreakGlassConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isGrantingEmergencyAccess {
                            ProgressView().controlSize(.small).tint(.white)
                        } else {
                            Image(systemName: "lock.open.trianglebadge.exclamationmark.fill")
                        }
                        Text("Grant 1-Hour Emergency Access")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .foregroundStyle(.white)
                    .background(
                        (viewModel.breakGlassTargetUser == nil || viewModel.emergencyAccessReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            ? Color.red.opacity(0.4)
                            : Color.red
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.breakGlassTargetUser == nil || viewModel.emergencyAccessReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGrantingEmergencyAccess)
                .alert("Confirm Emergency Access", isPresented: $viewModel.showBreakGlassConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Grant Access", role: .destructive) {
                        if let adminId = appViewModel.currentUser?.id,
                           let targetUser = viewModel.breakGlassTargetUser {
                            viewModel.grantEmergencyAccess(
                                adminId: adminId,
                                targetUser: targetUser,
                                reason: viewModel.emergencyAccessReason
                            )
                        }
                    }
                } message: {
                    Text("This will grant 1-hour emergency access to \(viewModel.breakGlassTargetUser?.fullName ?? "this user")'s data. The user will be notified and this action will be permanently logged.")
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

            // Active / Recent access log
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Access Log")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button {
                        if let adminId = appViewModel.currentUser?.id {
                            viewModel.loadEmergencyAccessLog(adminId: adminId)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                if viewModel.emergencyAccessLog.isEmpty {
                    emptyState(icon: "lock.shield.fill", message: "No emergency access events recorded")
                } else {
                    ForEach(viewModel.emergencyAccessLog) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.targetUserName)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text(entry.statusLabel)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .foregroundStyle(entry.isActive ? .white : AppTheme.textSecondary)
                                    .background(entry.isActive ? Color.red : AppTheme.background)
                                    .clipShape(Capsule())
                            }
                            Text("Reason: \(entry.reason)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                            Text(entry.grantedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))

                            if entry.isActive {
                                Button {
                                    if let adminId = appViewModel.currentUser?.id {
                                        viewModel.revokeEmergencyAccess(entryId: entry.id, adminId: adminId)
                                    }
                                } label: {
                                    Label("Revoke Now", systemImage: "xmark.shield.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(10)
                        .background(entry.isActive ? Color.red.opacity(0.06) : AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Divider()
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .padding(.horizontal)
        .onAppear {
            if let adminId = appViewModel.currentUser?.id {
                viewModel.loadEmergencyAccessLog(adminId: adminId)
            }
        }
    }
}
