import SwiftUI
import Supabase

// MARK: - Sobriety Change Notification Model

struct SobrietyChangeNotification: Identifiable {
    let id = UUID()
    let user: User
    let previousDate: Date
    let newDate: Date
    let changedAt: Date
    var isRead: Bool = false

    var wasReset: Bool {
        newDate > previousDate
    }
}

// MARK: - Badge Earned Notification Model

struct BadgeEarnedNotification: Identifiable {
    let id = UUID()
    let user: User
    let badge: Badge
    let earnedAt: Date
    var isRead: Bool = false
}

// MARK: - Pending User Notification Model

struct PendingUserNotification: Identifiable {
    let id = UUID()
    let user: User
    let requestedAt: Date
    var isRead: Bool = false
}

// MARK: - Admin News / Reflection Item

struct AdminContentItem: Identifiable {
    let id: UUID
    var title: String
    var body: String
    var type: ContentType
    var isPinned: Bool
    var createdAt: Date

    enum ContentType: String, CaseIterable {
        case reflection, news, pinnedUpdate

        var displayName: String {
            switch self {
            case .reflection: return "Reflection"
            case .news: return "News"
            case .pinnedUpdate: return "Pinned Update"
            }
        }

        var iconName: String {
            switch self {
            case .reflection: return "quote.opening"
            case .news: return "newspaper.fill"
            case .pinnedUpdate: return "pin.fill"
            }
        }

        var color: Color {
            switch self {
            case .reflection: return AppTheme.accentLight
            case .news: return AppTheme.accent
            case .pinnedUpdate: return AppTheme.accentSage
            }
        }
    }
}

// MARK: - Chat Moderation Status

enum ChatModerationStatus: String {
    case none           // Not flagged
    case flagged        // Flagged, awaiting review
    case allowed        // Reviewed and allowed
    case denied         // Reviewed and denied/removed
}

// MARK: - Chat Monitor Entry

struct ChatMonitorEntry: Identifiable {
    let id = UUID()
    let alumniName: String
    let staffName: String
    let staffRole: UserRole
    let lastMessagePreview: String
    let lastMessageAt: Date
    var flagged: Bool
    var moderationStatus: ChatModerationStatus
    let messageCount: Int
}

@Observable
final class AdminViewModel {

    // MARK: - Existing Properties
    var pendingPosts: [CommunityPost] = []
    var approvedPosts: [CommunityPost] = []
    var allUsers: [User] = []
    var isLoading = false

    // MARK: - Pending User Approvals
    var pendingUsers: [User] = []
    var pendingUserNotifications: [PendingUserNotification] = []
    /// Admin's own facility — set by AdminDashboardScreen on appear. Nil = super_admin (sees all).
    var adminFacilityFilter: Facility? = nil
    /// The signed-in admin's own user id — set by AdminDashboardScreen on appear.
    /// Used for `created_by` on meetings so we never write a fabricated author id.
    var currentAdminUserId: UUID? = nil
    /// Surfaced to the admin UI when a staff-photo upload (or similar admin
    /// action) fails, so failures are visible rather than silently swallowed.
    var adminActionError: String? = nil
    /// Per-user facility overrides: admin can change a user's claimed facility before approving.
    var facilityOverrides: [UUID: Facility] = [:]
    var unreadPendingUserCount: Int {
        pendingUsers.count
    }

    /// Returns the facility to assign for a given pending user (override if set, else user's claimed facility).
    func effectiveFacility(for user: User) -> Facility {
        facilityOverrides[user.id] ?? user.facility ?? .florida
    }

    // MARK: - Badge Earned Notifications
    var badgeNotifications: [BadgeEarnedNotification] = []
    var unreadBadgeNotificationCount: Int {
        badgeNotifications.filter { !$0.isRead }.count
    }

    // MARK: - Sobriety Tracking
    var alumniUsers: [User] = []
    var sobrietyNotifications: [SobrietyChangeNotification] = []
    var sobrietySearchText = ""
    var unreadNotificationCount: Int {
        sobrietyNotifications.filter { !$0.isRead }.count + unreadBadgeNotificationCount + unreadPendingUserCount
    }
    var filteredAlumni: [User] {
        if sobrietySearchText.isEmpty { return alumniUsers }
        return alumniUsers.filter { $0.fullName.localizedCaseInsensitiveContains(sobrietySearchText) }
    }

    // MARK: - Staff Assignment & Photo Upload
    var staffMembers: [User] = []
    var staffAssignments: [UUID: [UUID]] = [:]  // alumniId -> [staffId, staffId, staffId]
    var staffPhotoUploadId: UUID? = nil  // Currently uploading photo for this staff
    var showStaffPhotoPicker = false
    var newStaffName = ""
    var newStaffRole: UserRole = .caseManager

    // MARK: - Content Management (Reflections / News / Pinned Updates)
    var contentItems: [AdminContentItem] = []
    var showingContentEditor = false
    var editingContentItem: AdminContentItem?
    var contentEditorTitle = ""
    var contentEditorBody = ""
    var contentEditorType: AdminContentItem.ContentType = .news
    var contentEditorIsPinned = false

    // MARK: - Contact Management
    var companyContacts: [CompanyContact] = []
    var crisisResources: [CrisisResource] = []
    var editingContactId: UUID?
    var contactEditName = ""
    var contactEditPhone = ""
    var contactEditRole = ""

    // MARK: - Chat Monitoring
    var chatMonitorEntries: [ChatMonitorEntry] = []
    var chatSearchText = ""
    var showFlaggedChatOnly: Bool = true

    // MARK: - Content Flags
    var contentFlags: [ContentFlag] = []
    var isLoadingContentFlags = false
    var contentFlagFilterStatus: ContentFlag.ReviewStatus? = nil  // nil = show all
    var pendingFlagCount: Int {
        contentFlags.filter { $0.reviewStatus == .pending || $0.reviewStatus == .escalated }.count
    }

    var filteredChatEntries: [ChatMonitorEntry] {
        var entries = chatMonitorEntries

        // Filter to flagged-only if toggle is on
        if showFlaggedChatOnly {
            entries = entries.filter {
                $0.flagged || $0.moderationStatus == .flagged || $0.moderationStatus == .denied
            }
        }

        // Apply search filter
        if !chatSearchText.isEmpty {
            entries = entries.filter {
                $0.alumniName.localizedCaseInsensitiveContains(chatSearchText) ||
                $0.staffName.localizedCaseInsensitiveContains(chatSearchText)
            }
        }

        return entries
    }

    // MARK: - RSVP Tracking
    var selectedRSVPMeeting: Meeting? = nil
    var showRSVPSheet: Bool = false

    func rsvpUsers(for meeting: Meeting) -> [User] {
        meeting.rsvpUserIds.compactMap { uid in
            alumniUsers.first(where: { $0.id == uid })
        }
    }

    // MARK: - Meeting Management
    var meetings: [Meeting] = []
    var showingMeetingEditor = false
    var editingMeeting: Meeting?
    var meetingTitle = ""
    var meetingDescription = ""
    var meetingType: MeetingType = .inPerson
    var meetingDate = Date()
    var meetingStartTime = Date()
    var meetingEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    var meetingLocation = ""
    var meetingVirtualLink = ""
    var meetingIsRecurring = false
    var meetingRecurrence: RecurrencePattern = .weekly

    // MARK: - User Management (Super Admin)
    var showPromoteConfirmation = false
    var userToPromote: User? = nil
    var selectedPromotionRole: UserRole = .admin

    // MARK: - Chat Moderation
    var showModerationModal = false
    var moderatingEntry: ChatMonitorEntry? = nil

    // MARK: - Gamification Admin Controls (Super Admin)
    var editableBadges: [Badge] = []
    var editablePointActions: [PointAction: Int] = [:]
    var showingBadgeEditor = false
    var editingBadge: Badge?
    var badgeEditorName = ""
    var badgeEditorDescription = ""
    var badgeEditorEmoji = ""
    var badgeEditorPoints = 0

    // MARK: - Badge Toast
    var showBadgeToast: Bool = false
    var badgeToastMessage: String = ""

    // MARK: - Invite Alumni
    var invitePhone = ""
    var inviteName = ""
    var inviteSending = false
    var inviteSuccess: String? = nil
    var inviteError: String? = nil

    // MARK: - Announcements CRUD
    var announcements: [Announcement] = []
    var showingAnnouncementEditor = false
    var editingAnnouncement: Announcement?
    var announcementEditorTitle = ""
    var announcementEditorDescription = ""

    // MARK: - Active Section
    var activeSection: AdminSection? = nil

    enum AdminSection: String, CaseIterable {
        case pendingApprovals = "Pending Approvals"
        case inviteAlumni = "Invite Alumni"
        case sobriety = "Sobriety Tracking"
        case assignments = "Staff Assignments"
        case content = "Content Management"
        case moderation = "Community Moderation"
        case contacts = "Contact Numbers"
        case chatMonitor = "Chat Monitoring"
        case meetingMgmt = "Meeting Management"
        case userManagement = "User Management"
        case gamification = "Gamification"
        case announcements = "Announcements"
        case contentFlags = "Content Flags"
        case emergencyAccess = "Emergency Access"

        var icon: String {
            switch self {
            case .pendingApprovals: return "person.badge.clock.fill"
            case .inviteAlumni: return "paperplane.fill"
            case .sobriety: return "calendar.badge.clock"
            case .assignments: return "person.2.badge.gearshape.fill"
            case .content: return "doc.text.fill"
            case .moderation: return "shield.checkered"
            case .contacts: return "phone.circle.fill"
            case .chatMonitor: return "eye.fill"
            case .meetingMgmt: return "calendar.badge.plus"
            case .userManagement: return "person.badge.key.fill"
            case .gamification: return "star.circle.fill"
            case .announcements: return "megaphone.fill"
            case .contentFlags: return "flag.fill"
            case .emergencyAccess: return "lock.open.trianglebadge.exclamationmark.fill"
            }
        }

        var color: Color {
            switch self {
            case .pendingApprovals: return AppTheme.struggling
            case .inviteAlumni: return AppTheme.primary
            case .sobriety: return AppTheme.accentMedium
            case .assignments: return AppTheme.primaryMedium
            case .content: return AppTheme.accentLight
            case .moderation: return AppTheme.strugglesColor
            case .contacts: return AppTheme.accentSage
            case .chatMonitor: return AppTheme.accent
            case .meetingMgmt: return AppTheme.accentLime
            case .userManagement: return AppTheme.primaryMedium
            case .gamification: return AppTheme.accentLime
            case .announcements: return AppTheme.accent
            case .contentFlags: return AppTheme.struggling
            case .emergencyAccess: return .red
            }
        }

        /// Sections accessible by the restricted Admin role
        static let adminSections: Set<AdminSection> = [
            .pendingApprovals, .inviteAlumni, .moderation, .sobriety, .meetingMgmt, .chatMonitor, .announcements, .content, .contentFlags
        ]

        /// Sections accessible by clinical staff (case manager / therapist /
        /// counselor): caseload monitoring + operational tools, but NOT user
        /// approvals, invites, or user management (those stay admin-only).
        static let staffSections: Set<AdminSection> = [
            .sobriety, .moderation, .meetingMgmt, .chatMonitor, .announcements, .contentFlags
        ]

        /// Sections accessible only by Super Admin
        static let superAdminOnlySections: Set<AdminSection> = [
            .assignments, .contacts, .userManagement, .gamification, .emergencyAccess
        ]

        /// Returns filtered sections based on the user's role
        static func sections(for role: UserRole) -> [AdminSection] {
            if role.isSuperAdmin {
                return allCases
            } else if role == .admin {
                return allCases.filter { adminSections.contains($0) }
            } else if role.isClinical {
                return allCases.filter { staffSections.contains($0) }
            }
            return []
        }
    }

    private let dataService: DataServiceProtocol
    private var reconnectObserver: (any NSObjectProtocol)?

    init(dataService: DataServiceProtocol = DefaultServices.dataService) {
        self.dataService = dataService
        setupReconnectObserver()
    }

    deinit {
        if let observer = reconnectObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Realtime Admin Subscriptions

    /// Subscribe to new pending/flagged posts and status changes in real time.
    func subscribeToAdminPostUpdates() {
        guard SupabaseConfig.isConfigured else { return }
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        RealtimeService.shared.subscribeToAdminPosts(
            onNewPending: { [weak self] post in
                guard let self else { return }
                if !self.pendingPosts.contains(where: { $0.id == post.id }) {
                    self.pendingPosts.insert(post, at: 0)
                }
            },
            onStatusChange: { [weak self] updatedPost in
                guard let self else { return }
                // Update in pending list
                if let index = self.pendingPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                    if updatedPost.status == .approved || updatedPost.status == .rejected {
                        self.pendingPosts.remove(at: index)
                    } else {
                        self.pendingPosts[index] = updatedPost
                    }
                }
                // Update in approved list
                if let index = self.approvedPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                    if updatedPost.status == .approved {
                        self.approvedPosts[index] = updatedPost
                    } else {
                        self.approvedPosts.remove(at: index)
                    }
                } else if updatedPost.status == .approved {
                    self.approvedPosts.insert(updatedPost, at: 0)
                }
            }
        )
    }

    /// Unsubscribe from admin post Realtime channel (call from onDisappear).
    func unsubscribeFromAdminPostUpdates() {
        RealtimeService.shared.unsubscribeFromAdminPosts()
    }

    /// Re-establishes Realtime subscriptions when the app returns to foreground.
    private func setupReconnectObserver() {
        reconnectObserver = NotificationCenter.default.addObserver(
            forName: RealtimeService.reconnectNeeded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.subscribeToAdminPostUpdates()
        }
    }

    // MARK: - Load All Data

    func loadData() {
        Task {
            await MainActor.run { isLoading = true }
            // Run real fetches concurrently
            async let pending = try? dataService.fetchPendingPosts()
            async let allPosts = try? dataService.fetchPosts(category: nil)
            async let meetingsResult = try? dataService.fetchMeetings()
            async let pendingUsersResult = try? dataService.fetchPendingUsers(facilityFilter: adminFacilityFilter)
            async let alumniResult = try? dataService.fetchAlumniUsers(facility: adminFacilityFilter)
            async let staffResult = try? dataService.fetchStaffMembers(facility: adminFacilityFilter)
            async let assignmentsResult = try? dataService.fetchStaffAssignments()
            // Notifications: last 30 days of sobriety changes, last 20 badges, last 20 flagged
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            async let sobrietyChanges = try? dataService.fetchSobrietyChanges(since: thirtyDaysAgo, facility: adminFacilityFilter)
            async let badgeAwards = try? dataService.fetchRecentBadgeAwards(limit: 20, facility: adminFacilityFilter)
            async let flaggedMessages = try? dataService.fetchFlaggedMessages(limit: 50, facility: adminFacilityFilter)
            async let announcementsResult = try? dataService.fetchAnnouncements()

            let pendingResult = await pending ?? []
            let allResult = await allPosts ?? []
            let meetingsData = await meetingsResult ?? []
            let pendingUsersData = await pendingUsersResult ?? []
            let alumniData = await alumniResult ?? []
            let staffData = await staffResult ?? []
            let assignmentsData = await assignmentsResult ?? []
            let sobrietyChangesData = await sobrietyChanges ?? []
            let badgeAwardsData = await badgeAwards ?? []
            let flaggedMessagesData = await flaggedMessages ?? []
            let announcementsData = await announcementsResult ?? []

            await MainActor.run {
                pendingPosts = pendingResult
                approvedPosts = allResult.filter { $0.status == .approved }

                // Pending user approvals
                pendingUsers = pendingUsersData
                pendingUserNotifications = pendingUsersData.map { user in
                    PendingUserNotification(user: user, requestedAt: user.createdAt)
                }

                // Real staff + alumni rosters. On a fresh/empty DB we show the real
                // (empty) result + a clean empty state — never inject fake alumni,
                // staff, or assignments (Apple reject + patient-safety risk).
                staffMembers = staffData
                alumniUsers = alumniData
                allUsers = alumniUsers + staffMembers

                // Real staff assignments (empty stays empty — no mock fallback)
                staffAssignments = [:]
                for assignment in assignmentsData {
                    staffAssignments[assignment.userId, default: []].append(assignment.staffId)
                }

                // Real sobriety notifications from sobriety_change_log. Empty DB →
                // no notifications (no mock fallback).
                sobrietyNotifications = sobrietyChangesData.map { row in
                    SobrietyChangeNotification(
                        user: alumniUsers.first(where: { $0.id == row.userId })
                            ?? User.placeholder(id: row.userId, fullName: row.userName),
                        previousDate: row.previousDate ?? row.newDate,
                        newDate: row.newDate,
                        changedAt: row.changedAt,
                        isRead: false
                    )
                }

                // Real badge notifications from user_badges. We resolve badge
                // metadata from the row itself (name/emoji) so we don't depend on
                // any seeded mock badge. Empty DB → no notifications.
                badgeNotifications = badgeAwardsData.map { row in
                    BadgeEarnedNotification(
                        user: alumniUsers.first(where: { $0.id == row.userId })
                            ?? User.placeholder(id: row.userId, fullName: row.userName),
                        badge: Badge(
                            id: row.badgeId,
                            name: row.badgeName,
                            description: "",
                            emoji: row.badgeEmoji,
                            pointsRequired: 0,
                            sortOrder: 0
                        ),
                        earnedAt: row.earnedAt,
                        isRead: false
                    )
                }

                checkNewBadgeNotifications()

                // Admin content items (reflections / news) have no backend yet —
                // start empty and show the empty state rather than fabricating
                // sample reflections that would ship in Release.
                contentItems = []

                // Crisis hotlines + Milton support numbers are fixed app config
                // (988, SAMHSA, Crisis Text Line, Milton line) — NOT fabricated
                // patient data. Sourced from AppContacts, shared with ContactsScreen.
                companyContacts = AppContacts.companyContacts
                crisisResources = AppContacts.crisisResources

                // Real flagged/crisis chat messages from Supabase (no fake crisis
                // lines). Empty result → the Chat Monitor shows its empty state.
                chatMonitorEntries = Self.buildChatMonitorEntries(from: flaggedMessagesData, alumni: alumniUsers, staff: staffMembers)

                meetings = meetingsData

                loadGamificationData()

                // Real announcements from Supabase (facility-filtered server-side).
                announcements = announcementsData

                isLoading = false
            }
        }
    }

    // MARK: - Sobriety Tracking

    func markNotificationRead(_ id: UUID) {
        if let index = sobrietyNotifications.firstIndex(where: { $0.id == id }) {
            sobrietyNotifications[index].isRead = true
        }
    }

    func markAllNotificationsRead() {
        for i in sobrietyNotifications.indices {
            sobrietyNotifications[i].isRead = true
        }
        for i in badgeNotifications.indices {
            badgeNotifications[i].isRead = true
        }
    }

    // MARK: - Pending User Approval Actions

    func approvePendingUser(userId: UUID) {
        guard let user = pendingUsers.first(where: { $0.id == userId }) else { return }
        let facility = effectiveFacility(for: user)
        Task {
            do {
                let approvedUser = try await dataService.approveUser(userId: userId, facility: facility)
                await MainActor.run {
                    pendingUsers.removeAll { $0.id == userId }
                    pendingUserNotifications.removeAll { $0.user.id == userId }
                    facilityOverrides.removeValue(forKey: userId)
                    AuditLogger.shared.log(.approveUser, userId: userId, detail: "Approved: \(approvedUser.fullName) → \(facility.displayName)")

                    // Approved-user notification is dispatched server-side via the
                    // approveUser → send-push-notification Edge Function pipeline.
                    // (Title: "You're Approved! 🎉" — see SupabaseDataService.approveUser.)
                    // Previously also fired a local notification here on the admin's
                    // device with stale "Milton Alumni" branding — removed to dedupe
                    // and avoid showing the approval text on the WRONG device.
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.approvePendingUser")
                #if DEBUG
                print("[AdminViewModel] Failed to approve user: \(error.localizedDescription)")
                #endif
            }
        }
    }

    func rejectPendingUser(userId: UUID) {
        Task {
            do {
                try await dataService.rejectUser(userId: userId)
                await MainActor.run {
                    let userName = pendingUsers.first(where: { $0.id == userId })?.fullName ?? "Unknown"
                    pendingUsers.removeAll { $0.id == userId }
                    pendingUserNotifications.removeAll { $0.user.id == userId }
                    AuditLogger.shared.log(.rejectUser, userId: userId, detail: "Rejected: \(userName)")
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.rejectPendingUser")
                #if DEBUG
                print("[AdminViewModel] Failed to reject user: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Refresh just the pending users list (called after push notification tap).
    func refreshPendingUsers() {
        Task {
            let users = (try? await dataService.fetchPendingUsers(facilityFilter: adminFacilityFilter)) ?? []
            await MainActor.run {
                pendingUsers = users
                pendingUserNotifications = users.map { user in
                    PendingUserNotification(user: user, requestedAt: user.createdAt)
                }
            }
        }
    }

    // MARK: - Badge Notifications

    func markBadgeNotificationRead(_ id: UUID) {
        if let index = badgeNotifications.firstIndex(where: { $0.id == id }) {
            badgeNotifications[index].isRead = true
        }
    }

    /// Checks for unread badge notifications and triggers a toast alert.
    func checkNewBadgeNotifications() {
        let unread = badgeNotifications.filter { !$0.isRead }
        guard let latest = unread.first else { return }

        if unread.count == 1 {
            badgeToastMessage = "\(latest.badge.emoji) \(latest.user.fullName) earned \(latest.badge.name)!"
        } else {
            badgeToastMessage = "\(latest.badge.emoji) \(unread.count) new badge notifications!"
        }

        // Show toast with a slight delay so the UI has time to render
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self?.showBadgeToast = true
            }
        }
    }

    // MARK: - Staff Assignment

    func assignStaff(alumniId: UUID, role: UserRole, staffId: UUID?) {
        var current = staffAssignments[alumniId] ?? []
        // Remove any existing staff member who holds this role
        current.removeAll { id in
            staffMembers.first(where: { $0.id == id })?.role == role
        }
        // Add the new staff member if provided
        if let staffId {
            current.append(staffId)
        }
        staffAssignments[alumniId] = current.isEmpty ? nil : current
    }

    func assignedStaff(for alumniId: UUID) -> [User] {
        guard let staffIds = staffAssignments[alumniId] else { return [] }
        return staffIds.compactMap { id in staffMembers.first(where: { $0.id == id }) }
    }

    func assignedStaffMember(for alumniId: UUID, role: UserRole) -> User? {
        assignedStaff(for: alumniId).first(where: { $0.role == role })
    }

    func addStaffMember(name: String, role: UserRole) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newStaff = User(
            id: UUID(),
            email: "\(trimmed.lowercased().replacingOccurrences(of: " ", with: "."))@miltonrecovery.com",
            phone: "(555) 000-0000",
            fullName: trimmed,
            username: trimmed.lowercased().replacingOccurrences(of: " ", with: "_"),
            profilePhotoURL: nil,
            sobrietyDate: Date(),
            dischargeDate: Date(),
            recoveryProgram: "",
            role: role,
            status: .active,
            mfaMethod: .email,
            totalPoints: 0,
            lastLogin: Date(),
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        staffMembers.append(newStaff)
        allUsers.append(newStaff)
        newStaffName = ""
    }

    // MARK: - Content Management (CRUD)
    //
    // Admin content items (reflections / news) are held in-memory for the current
    // session only — there is no backend table for them yet. `loadData()` seeds
    // this to an empty array so a fresh install shows the empty state instead of
    // fabricated sample reflections in Release.

    func beginCreateContent() {
        editingContentItem = nil
        contentEditorTitle = ""
        contentEditorBody = ""
        contentEditorType = .news
        contentEditorIsPinned = false
        showingContentEditor = true
    }

    func beginEditContent(_ item: AdminContentItem) {
        editingContentItem = item
        contentEditorTitle = item.title
        contentEditorBody = item.body
        contentEditorType = item.type
        contentEditorIsPinned = item.isPinned
        showingContentEditor = true
    }

    func saveContent() {
        guard !contentEditorTitle.isEmpty, !contentEditorBody.isEmpty else { return }

        if let existing = editingContentItem,
           let index = contentItems.firstIndex(where: { $0.id == existing.id }) {
            contentItems[index].title = contentEditorTitle
            contentItems[index].body = contentEditorBody
            contentItems[index].type = contentEditorType
            contentItems[index].isPinned = contentEditorIsPinned
        } else {
            let newItem = AdminContentItem(
                id: UUID(),
                title: contentEditorTitle,
                body: contentEditorBody,
                type: contentEditorType,
                isPinned: contentEditorIsPinned,
                createdAt: Date()
            )
            contentItems.insert(newItem, at: 0)
        }
        showingContentEditor = false
        editingContentItem = nil
    }

    func deleteContent(_ item: AdminContentItem) {
        contentItems.removeAll { $0.id == item.id }
    }

    func toggleContentPin(_ item: AdminContentItem) {
        if let index = contentItems.firstIndex(where: { $0.id == item.id }) {
            contentItems[index].isPinned.toggle()
        }
    }

    // MARK: - Community Moderation (Existing)

    func moderatePost(postId: UUID, action: PostStatus) {
        Task {
            _ = try? await dataService.moderatePost(postId: postId, action: action)
            await MainActor.run {
                if let index = pendingPosts.firstIndex(where: { $0.id == postId }) {
                    var post = pendingPosts.remove(at: index)
                    post.status = action
                    if action == .approved {
                        post.approvedAt = Date()
                        approvedPosts.insert(post, at: 0)
                        AuditLogger.shared.log(.approvePost, detail: "Post \(postId)")

                        // Increment the post author's approved count
                        if let userIndex = alumniUsers.firstIndex(where: { $0.id == post.userId }) {
                            alumniUsers[userIndex].approvedPostCount += 1
                        }

                        // Notify the user their post was approved
                        notifyPostAuthor(
                            userName: post.userName,
                            title: "Post Approved",
                            body: "Your community post has been approved and is now visible to everyone."
                        )
                    } else if action == .rejected {
                        AuditLogger.shared.log(.rejectPost, detail: "Post \(postId)")

                        // Notify the user their post was rejected.
                        // Softer tone for the recovery context — "rejected" can land hard
                        // for someone in early recovery. We acknowledge, open the door to
                        // care team support, and invite a re-try rather than scolding.
                        notifyPostAuthor(
                            userName: post.userName,
                            title: "We couldn't publish your post",
                            body: "Your latest community post didn't quite fit the guidelines. Open the app to revise it — your care team is here if you'd like to talk."
                        )
                    } else {
                        AuditLogger.shared.log(.rejectPost, detail: "Post \(postId)")
                    }
                }

                // Track analytics
                AnalyticsService.shared.track(
                    action == .approved ? .postCreated : .error,
                    properties: ["action": "moderate_\(action.rawValue)", "post_id": postId.uuidString]
                )
            }
        }
    }

    /// Send a push notification to the post author about moderation outcome.
    private func notifyPostAuthor(userName: String, title: String, body: String) {
        PushNotificationService.shared.scheduleLocalNotification(
            title: title,
            body: body
        )
    }

    func togglePin(postId: UUID) {
        Task {
            guard let index = approvedPosts.firstIndex(where: { $0.id == postId }) else { return }
            let newPinned = !approvedPosts[index].isPinned
            _ = try? await dataService.pinPost(postId: postId, isPinned: newPinned)
            await MainActor.run {
                approvedPosts[index].isPinned = newPinned
                AuditLogger.shared.log(newPinned ? .pinPost : .unpinPost, detail: "Post \(postId)")
            }
        }
    }

    // MARK: - Contact Management

    func beginEditContact(_ contact: CompanyContact) {
        editingContactId = contact.id
        contactEditName = contact.name
        contactEditPhone = contact.phoneNumber
        contactEditRole = contact.role ?? ""
    }

    func saveContact() {
        guard let editId = editingContactId,
              let index = companyContacts.firstIndex(where: { $0.id == editId }) else { return }
        companyContacts[index].name = contactEditName
        companyContacts[index].phoneNumber = contactEditPhone
        companyContacts[index].role = contactEditRole.isEmpty ? nil : contactEditRole
        editingContactId = nil
    }

    func cancelEditContact() {
        editingContactId = nil
    }

    func addNewContact() {
        let newContact = CompanyContact(name: "New Contact", phoneNumber: "(555) 000-0000", role: "Role")
        companyContacts.append(newContact)
        beginEditContact(newContact)
    }

    func deleteContact(_ contact: CompanyContact) {
        companyContacts.removeAll { $0.id == contact.id }
    }

    // MARK: - Chat Monitoring

    /// Build the admin Chat Monitor list from REAL flagged/crisis messages
    /// fetched from Supabase (`fetchFlaggedMessages`). No fabricated messages or
    /// fake crisis lines — an empty result yields an empty list and the UI shows
    /// its empty state. Sender names are resolved from the real alumni/staff
    /// rosters; unresolved senders fall back to a generic "Member" label.
    static func buildChatMonitorEntries(
        from messages: [ChatMessage],
        alumni: [User],
        staff: [User]
    ) -> [ChatMonitorEntry] {
        let byId: [UUID: User] = Dictionary(
            (alumni + staff).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return messages.map { message in
            let sender = byId[message.senderId]
            let senderIsStaff = sender?.role.isStaff ?? false
            // The flagged message is authored by `senderId`. If a staff member,
            // surface it in the staff column; otherwise treat the author as the
            // member being monitored.
            let alumniName = senderIsStaff ? "Member" : (sender?.fullName ?? "Member")
            let staffName = senderIsStaff ? (sender?.fullName ?? "Staff") : "—"
            let staffRole = sender?.role ?? .caseManager

            let modStatus: ChatModerationStatus = message.status == .flaggedForCrisis
                || message.status == .denied ? .denied : .flagged

            return ChatMonitorEntry(
                alumniName: alumniName,
                staffName: staffName,
                staffRole: staffRole,
                lastMessagePreview: message.content ?? message.messageType.rawValue.capitalized,
                lastMessageAt: message.createdAt,
                flagged: true,
                moderationStatus: modStatus,
                messageCount: 1
            )
        }
    }

    // MARK: - Chat Moderation Actions

    func beginModeration(_ entry: ChatMonitorEntry) {
        moderatingEntry = entry
        showModerationModal = true
    }

    func allowFlaggedMessage(_ entryId: UUID) {
        if let index = chatMonitorEntries.firstIndex(where: { $0.id == entryId }) {
            chatMonitorEntries[index].flagged = false
            chatMonitorEntries[index].moderationStatus = .allowed
            AuditLogger.shared.log(.allowFlaggedMessage, detail: "Entry \(entryId)")
        }
        showModerationModal = false
        moderatingEntry = nil
    }

    func denyFlaggedMessage(_ entryId: UUID) {
        if let index = chatMonitorEntries.firstIndex(where: { $0.id == entryId }) {
            chatMonitorEntries[index].moderationStatus = .denied
            AuditLogger.shared.log(.denyFlaggedMessage, detail: "Entry \(entryId)")
        }
        showModerationModal = false
        moderatingEntry = nil
    }

    // MARK: - User Management (Promotion)

    func beginPromoteUser(_ user: User, to role: UserRole = .admin) {
        userToPromote = user
        selectedPromotionRole = role
        showPromoteConfirmation = true
    }

    func confirmPromoteUser() {
        guard let user = userToPromote,
              let index = alumniUsers.firstIndex(where: { $0.id == user.id }) else {
            showPromoteConfirmation = false
            userToPromote = nil
            return
        }
        alumniUsers[index].role = selectedPromotionRole
        // Also update in allUsers
        if let allIndex = allUsers.firstIndex(where: { $0.id == user.id }) {
            allUsers[allIndex].role = selectedPromotionRole
        }
        AuditLogger.shared.log(.promoteUser, userId: user.id, detail: "To: \(selectedPromotionRole.rawValue)")
        showPromoteConfirmation = false
        userToPromote = nil
    }

    func cancelPromotion() {
        showPromoteConfirmation = false
        userToPromote = nil
    }

    // MARK: - Meeting Management

    func beginCreateMeeting() {
        editingMeeting = nil
        meetingTitle = ""
        meetingDescription = ""
        meetingType = .inPerson
        meetingDate = Date()
        meetingStartTime = Date()
        meetingEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        meetingLocation = ""
        meetingVirtualLink = ""
        meetingIsRecurring = false
        meetingRecurrence = .weekly
        showingMeetingEditor = true
    }

    func beginEditMeeting(_ meeting: Meeting) {
        editingMeeting = meeting
        meetingTitle = meeting.title
        meetingDescription = meeting.description ?? ""
        meetingType = meeting.meetingType
        meetingDate = meeting.date
        meetingStartTime = meeting.startTime
        meetingEndTime = meeting.endTime
        meetingLocation = meeting.locationAddress ?? ""
        meetingVirtualLink = meeting.virtualLink ?? ""
        meetingIsRecurring = meeting.isRecurring
        meetingRecurrence = meeting.recurrencePattern ?? .weekly
        showingMeetingEditor = true
    }

    func saveMeeting() {
        guard !meetingTitle.isEmpty else { return }
        let isUpdate = editingMeeting != nil
        let meetingToSave: Meeting
        if let existing = editingMeeting {
            var updated = existing
            updated.title = meetingTitle
            updated.description = meetingDescription.isEmpty ? nil : meetingDescription
            updated.meetingType = meetingType
            updated.date = meetingDate
            updated.startTime = meetingStartTime
            updated.endTime = meetingEndTime
            updated.locationAddress = meetingLocation.isEmpty ? nil : meetingLocation
            updated.virtualLink = meetingVirtualLink.isEmpty ? nil : meetingVirtualLink
            updated.isRecurring = meetingIsRecurring
            updated.recurrencePattern = meetingIsRecurring ? meetingRecurrence : nil
            meetingToSave = updated
        } else {
            meetingToSave = Meeting(
                id: UUID(),
                title: meetingTitle,
                description: meetingDescription.isEmpty ? nil : meetingDescription,
                meetingType: meetingType,
                date: meetingDate,
                startTime: meetingStartTime,
                endTime: meetingEndTime,
                locationAddress: meetingLocation.isEmpty ? nil : meetingLocation,
                locationLat: nil, locationLng: nil,
                virtualLink: meetingVirtualLink.isEmpty ? nil : meetingVirtualLink,
                isRecurring: meetingIsRecurring,
                recurrencePattern: meetingIsRecurring ? meetingRecurrence : nil,
                recurrenceEndDate: nil,
                parentMeetingId: nil,
                // Real signed-in admin id (set by AdminDashboardScreen.onAppear).
                // Falls back to the existing editing meeting's author, then to a
                // zero UUID only if somehow unset — never a fabricated mock user.
                createdBy: currentAdminUserId ?? editingMeeting?.createdBy ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                createdAt: Date()
            )
        }

        // Optimistic local update so the admin sees the change immediately
        if isUpdate {
            if let idx = meetings.firstIndex(where: { $0.id == meetingToSave.id }) {
                meetings[idx] = meetingToSave
            }
        } else {
            meetings.insert(meetingToSave, at: 0)
        }
        showingMeetingEditor = false
        editingMeeting = nil

        // Persist to Supabase — without this the admin's edit was wiped on next loadData()
        Task {
            do {
                if isUpdate {
                    _ = try await dataService.updateMeeting(meetingToSave)
                    await MainActor.run {
                        AuditLogger.shared.log(.updateMeeting, detail: meetingToSave.title)
                    }
                } else {
                    _ = try await dataService.createMeeting(meetingToSave)
                    await MainActor.run {
                        AuditLogger.shared.log(.createMeeting, detail: meetingToSave.title)
                    }
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.saveMeeting")
                // Roll back local state on failure
                await MainActor.run {
                    if !isUpdate {
                        meetings.removeAll { $0.id == meetingToSave.id }
                    }
                }
            }
        }
    }

    func deleteMeeting(_ meeting: Meeting) {
        AuditLogger.shared.log(.deleteMeeting, detail: meeting.title)
        // Optimistic remove
        meetings.removeAll { $0.id == meeting.id }
        // Persist
        Task {
            do {
                try await dataService.deleteMeeting(meetingId: meeting.id)
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.deleteMeeting")
                // Roll back on failure
                await MainActor.run {
                    if !meetings.contains(where: { $0.id == meeting.id }) {
                        meetings.append(meeting)
                        meetings.sort { $0.date < $1.date }
                    }
                }
            }
        }
    }

    // MARK: - Staff Photo Upload

    func beginPhotoUpload(for staffId: UUID) {
        staffPhotoUploadId = staffId
        showStaffPhotoPicker = true
    }

    func completePhotoUpload(photoURL: String) {
        guard let staffId = staffPhotoUploadId,
              let index = staffMembers.firstIndex(where: { $0.id == staffId }) else { return }
        staffMembers[index].profilePhotoURL = photoURL
        staffPhotoUploadId = nil
        showStaffPhotoPicker = false
    }

    /// Upload staff photo to Supabase Storage and persist the URL to the profiles table.
    /// Surfaces failures to the admin via `adminActionError` (bound to an alert in
    /// the dashboard) instead of failing silently.
    func uploadStaffPhoto(data: Data, staffId: UUID) async {
        guard SupabaseConfig.isConfigured else {
            await MainActor.run {
                adminActionError = "Photo upload is unavailable in this build."
                staffPhotoUploadId = nil
                showStaffPhotoPicker = false
            }
            return
        }
        let path = "staff-photos/\(staffId.uuidString).jpg"
        do {
            try await SupabaseConfig.client.storage
                .from("profile-photos")
                .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))

            let publicURL = try SupabaseConfig.client.storage
                .from("profile-photos")
                .getPublicURL(path: path)

            let urlString = publicURL.absoluteString

            // Update in-memory model
            await MainActor.run { completePhotoUpload(photoURL: urlString) }

            // Persist to profiles table — surface a failure here too (previously
            // this used try? and swallowed DB errors, so the photo could look
            // saved locally but never persist).
            try await SupabaseConfig.client.from("profiles")
                .update(["profile_photo_url": urlString])
                .eq("id", value: staffId.uuidString)
                .execute()
        } catch {
            CrashReportingService.shared.recordError(error, context: "AdminViewModel.uploadStaffPhoto")
            await MainActor.run {
                adminActionError = "Couldn't upload the staff photo. Please try again.\n\(error.localizedDescription)"
                staffPhotoUploadId = nil
                showStaffPhotoPicker = false
            }
            #if DEBUG
            print("[AdminViewModel] Photo upload failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Gamification Admin Controls

    private func loadGamificationData() {
        // Point values are real app config (the PointAction enum), not fabricated
        // data — safe to show in Release.
        editablePointActions = [
            .dailyLogin: PointAction.dailyLogin.points,
            .postCreated: PointAction.postCreated.points,
            .postLiked: PointAction.postLiked.points,
            .milestoneReached: PointAction.milestoneReached.points,
        ]
        // Badges load from the real `badges` table. Empty DB → empty editor
        // (no mock badge ladder shipped in Release).
        editableBadges = []
        Task {
            let badges = (try? await dataService.fetchBadges()) ?? []
            await MainActor.run { editableBadges = badges }
        }
    }

    func beginEditBadge(_ badge: Badge) {
        editingBadge = badge
        badgeEditorName = badge.name
        badgeEditorDescription = badge.description
        badgeEditorEmoji = badge.emoji
        badgeEditorPoints = badge.pointsRequired
        showingBadgeEditor = true
    }

    func saveBadgeEdit() {
        guard let existing = editingBadge,
              let index = editableBadges.firstIndex(where: { $0.id == existing.id }) else { return }
        editableBadges[index].name = badgeEditorName
        editableBadges[index].description = badgeEditorDescription
        editableBadges[index].emoji = badgeEditorEmoji
        editableBadges[index].pointsRequired = badgeEditorPoints
        showingBadgeEditor = false
        editingBadge = nil
    }

    func cancelBadgeEdit() {
        showingBadgeEditor = false
        editingBadge = nil
    }

    // MARK: - Announcements CRUD

    func loadAnnouncements() {
        Task {
            let fetched = try? await dataService.fetchAnnouncements()
            await MainActor.run {
                announcements = fetched ?? []
            }
        }
    }

    func beginCreateAnnouncement() {
        editingAnnouncement = nil
        announcementEditorTitle = ""
        announcementEditorDescription = ""
        showingAnnouncementEditor = true
    }

    func beginEditAnnouncement(_ item: Announcement) {
        editingAnnouncement = item
        announcementEditorTitle = item.title
        announcementEditorDescription = item.description
        showingAnnouncementEditor = true
    }

    func saveAnnouncement() {
        guard !announcementEditorTitle.isEmpty, !announcementEditorDescription.isEmpty else { return }

        Task {
            if let existing = editingAnnouncement {
                _ = try? await dataService.updateAnnouncement(
                    id: existing.id,
                    title: announcementEditorTitle,
                    description: announcementEditorDescription
                )
                AuditLogger.shared.log(.updateAnnouncement, detail: announcementEditorTitle)
            } else {
                _ = try? await dataService.createAnnouncement(
                    title: announcementEditorTitle,
                    description: announcementEditorDescription
                )
                AuditLogger.shared.log(.createAnnouncement, detail: announcementEditorTitle)
            }
            // Re-fetch to stay in sync with MockData
            let fetched = try? await dataService.fetchAnnouncements()
            await MainActor.run {
                announcements = fetched ?? []
                showingAnnouncementEditor = false
                editingAnnouncement = nil
            }
        }
    }

    func deleteAnnouncement(_ item: Announcement) {
        AuditLogger.shared.log(.deleteAnnouncement, detail: item.title)
        Task {
            try? await dataService.deleteAnnouncement(id: item.id)
            let fetched = try? await dataService.fetchAnnouncements()
            await MainActor.run {
                announcements = fetched ?? []
            }
        }
    }

    // MARK: - Invite Alumni

    func sendInvite() {
        let phone = invitePhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = inviteName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !phone.isEmpty else {
            inviteError = "Please enter a phone number."
            return
        }

        inviteSending = true
        inviteError = nil
        inviteSuccess = nil

        Task {
            do {
                let maskedPhone = try await dataService.sendInvite(
                    phone: phone,
                    name: name.isEmpty ? nil : name
                )
                await MainActor.run {
                    inviteSending = false
                    inviteSuccess = "Invite sent to \(maskedPhone)"
                    invitePhone = ""
                    inviteName = ""
                    AuditLogger.shared.log(.sendInvite, detail: "Invited \(maskedPhone)\(name.isEmpty ? "" : " (\(name))")")
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.sendInvite")
                await MainActor.run {
                    inviteSending = false
                    inviteError = error.localizedDescription
                }
                #if DEBUG
                print("[AdminViewModel] Failed to send invite: \(error.localizedDescription)")
                #endif
            }
        }
    }

    func clearInviteStatus() {
        inviteSuccess = nil
        inviteError = nil
    }

    // MARK: - Content Flags Loading & Review

    func loadContentFlags() {
        guard SupabaseConfig.isConfigured else { return }
        isLoadingContentFlags = true
        Task {
            do {
                let flags: [ContentFlag] = try await SupabaseConfig.client
                    .from("content_flags")
                    .select()
                    .order("timestamp", ascending: false)
                    .limit(200)
                    .execute()
                    .value
                await MainActor.run {
                    self.contentFlags = flags
                    self.isLoadingContentFlags = false
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.loadContentFlags")
                await MainActor.run { self.isLoadingContentFlags = false }
                #if DEBUG
                print("[AdminViewModel] ⚠️ Failed to load content flags: \(error)")
                #endif
            }
        }
    }

    func reviewFlag(_ flag: ContentFlag, note: String? = nil) {
        updateFlagStatus(flag.id, status: .reviewed, note: note)
    }

    func dismissFlag(_ flag: ContentFlag, note: String? = nil) {
        updateFlagStatus(flag.id, status: .dismissed, note: note)
    }

    func escalateFlag(_ flag: ContentFlag, note: String? = nil) {
        updateFlagStatus(flag.id, status: .escalated, note: note)
    }

    private func updateFlagStatus(_ flagId: UUID, status: ContentFlag.ReviewStatus, note: String?) {
        guard SupabaseConfig.isConfigured else { return }
        struct UpdateParams: Encodable {
            let reviewStatus: String
            let reviewNote: String?
            enum CodingKeys: String, CodingKey {
                case reviewStatus = "review_status"
                case reviewNote   = "review_note"
            }
        }
        Task {
            do {
                try await SupabaseConfig.client
                    .from("content_flags")
                    .update(UpdateParams(reviewStatus: status.rawValue, reviewNote: note))
                    .eq("id", value: flagId.uuidString)
                    .execute()
                await MainActor.run {
                    if let idx = self.contentFlags.firstIndex(where: { $0.id == flagId }) {
                        self.contentFlags[idx].reviewStatus = status
                        if let note = note { self.contentFlags[idx].reviewNote = note }
                    }
                }
                let auditAction: AuditAction = status == .dismissed ? .contentFlagDismissed : .contentFlagReviewed
                AuditLogger.shared.log(auditAction, detail: "flagId:\(flagId.uuidString) → \(status.rawValue)")
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.updateFlagStatus:\(flagId.uuidString.prefix(8))")
                #if DEBUG
                print("[AdminViewModel] ⚠️ Failed to update flag \(flagId): \(error)")
                #endif
            }
        }
    }

    // MARK: - Break-Glass Emergency Access

    /// Represents a single emergency access grant in the audit log.
    struct EmergencyAccessEntry: Identifiable {
        let id: UUID
        let adminId: UUID
        let adminName: String
        let targetUserId: UUID
        let targetUserName: String
        let reason: String
        let grantedAt: Date
        let expiresAt: Date
        var revokedAt: Date?

        var isActive: Bool {
            revokedAt == nil && Date() < expiresAt
        }

        var statusLabel: String {
            if let revoked = revokedAt {
                return "Revoked \(revoked.formatted(.relative(presentation: .named)))"
            } else if Date() >= expiresAt {
                return "Expired"
            } else {
                let remaining = Int(expiresAt.timeIntervalSinceNow / 60)
                return "Active — expires in \(remaining)m"
            }
        }
    }

    // Break-glass UI state
    var emergencyAccessLog: [EmergencyAccessEntry] = []
    var emergencyAccessReason: String = ""
    var isGrantingEmergencyAccess = false
    var showBreakGlassConfirmation = false
    var breakGlassTargetUser: User?
    var emergencyAccessError: String?

    /// Load the emergency access audit log from Supabase.
    func loadEmergencyAccessLog(adminId: UUID) {
        Task {
            guard SupabaseConfig.isConfigured else {
                // Mock data for simulator
                await MainActor.run {
                    emergencyAccessLog = []
                }
                return
            }
            do {
                struct EALRow: Decodable {
                    let id: UUID
                    let admin_id: UUID
                    let target_user_id: UUID
                    let reason: String
                    let granted_at: Date
                    let expires_at: Date
                    let revoked_at: Date?
                }
                let rows: [EALRow] = try await SupabaseConfig.client
                    .from("emergency_access_log")
                    .select()
                    .order("granted_at", ascending: false)
                    .limit(50)
                    .execute()
                    .value

                let entries = rows.map { row in
                    EmergencyAccessEntry(
                        id: row.id,
                        adminId: row.admin_id,
                        adminName: "Super Admin",
                        targetUserId: row.target_user_id,
                        targetUserName: allUsers.first(where: { $0.id == row.target_user_id })?.fullName ?? "Unknown User",
                        reason: row.reason,
                        grantedAt: row.granted_at,
                        expiresAt: row.expires_at,
                        revokedAt: row.revoked_at
                    )
                }
                await MainActor.run { emergencyAccessLog = entries }
            } catch {
                CrashReportingService.shared.recordError(error, context: "AdminViewModel.loadEmergencyAccessLog")
            }
        }
    }

    /// Grant 1-hour emergency access to a target user's data.
    func grantEmergencyAccess(adminId: UUID, targetUser: User, reason: String) {
        Task {
            await MainActor.run {
                isGrantingEmergencyAccess = true
                emergencyAccessError = nil
            }

            let expiresAt = Date().addingTimeInterval(3600) // 1 hour

            if SupabaseConfig.isConfigured {
                do {
                    struct InsertPayload: Encodable {
                        let admin_id: String
                        let target_user_id: String
                        let reason: String
                        let expires_at: String
                    }
                    let iso = ISO8601DateFormatter()
                    let payload = InsertPayload(
                        admin_id: adminId.uuidString,
                        target_user_id: targetUser.id.uuidString,
                        reason: reason,
                        expires_at: iso.string(from: expiresAt)
                    )
                    try await SupabaseConfig.client
                        .from("emergency_access_log")
                        .insert(payload)
                        .execute()
                } catch {
                    CrashReportingService.shared.recordError(error, context: "AdminViewModel.grantEmergencyAccess")
                    await MainActor.run {
                        emergencyAccessError = "Failed to log emergency access. Try again."
                        isGrantingEmergencyAccess = false
                    }
                    return
                }
            }

            AuditLogger.shared.log(
                .emergencyAccessGranted,
                userId: adminId,
                detail: "target:\(targetUser.id.uuidString.prefix(8)) reason:\(reason.prefix(80))"
            )

            // Notify the affected user via local notification (real device would get APNS push)
            // HIPAA breach-notification-style alert. Be explicit about WHY (care
            // and safety review) and HOW TO RESPOND (real Milton phone number).
            // The bare "Privacy Notice" wording could spook the user without
            // context — this version sets the safety frame.
            PushNotificationService.shared.scheduleLocalNotification(
                title: "Account Access Notice",
                body: "For your safety, a Milton care team member reviewed your account today. If you have any questions, call (844) 406-4325.",
                userInfo: ["type": "emergency_access_notice", "userId": targetUser.id.uuidString]
            )

            await MainActor.run {
                isGrantingEmergencyAccess = false
                emergencyAccessReason = ""
                breakGlassTargetUser = nil
                showBreakGlassConfirmation = false
            }

            loadEmergencyAccessLog(adminId: adminId)
        }
    }

    /// Revoke an active emergency access grant immediately.
    func revokeEmergencyAccess(entryId: UUID, adminId: UUID) {
        Task {
            if SupabaseConfig.isConfigured {
                do {
                    struct RevokePayload: Encodable {
                        let revoked_at: String
                    }
                    let iso = ISO8601DateFormatter()
                    let payload = RevokePayload(revoked_at: iso.string(from: Date()))
                    try await SupabaseConfig.client
                        .from("emergency_access_log")
                        .update(payload)
                        .eq("id", value: entryId.uuidString)
                        .execute()
                } catch {
                    CrashReportingService.shared.recordError(error, context: "AdminViewModel.revokeEmergencyAccess")
                    return
                }
            }
            AuditLogger.shared.log(
                .emergencyAccessRevoked,
                userId: adminId,
                detail: "entryId:\(entryId.uuidString.prefix(8))"
            )
            loadEmergencyAccessLog(adminId: adminId)
        }
    }
}
