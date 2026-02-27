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
    var unreadPendingUserCount: Int {
        pendingUsers.count
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
            }
        }

        /// Sections accessible by the restricted Admin role
        static let adminSections: Set<AdminSection> = [
            .pendingApprovals, .inviteAlumni, .moderation, .sobriety, .meetingMgmt, .chatMonitor, .announcements, .content, .contentFlags
        ]

        /// Sections accessible only by Super Admin
        static let superAdminOnlySections: Set<AdminSection> = [
            .assignments, .contacts, .userManagement, .gamification
        ]

        /// Returns filtered sections based on the user's role
        static func sections(for role: UserRole) -> [AdminSection] {
            if role.isSuperAdmin {
                return allCases
            } else if role == .admin {
                return allCases.filter { adminSections.contains($0) }
            }
            return []
        }
    }

    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = MockDataService()) {
        self.dataService = dataService
    }

    // MARK: - Load All Data

    func loadData() {
        Task {
            isLoading = true
            async let pending = try? dataService.fetchPendingPosts()
            async let allPosts = try? dataService.fetchPosts(category: nil)
            async let meetingsResult = try? dataService.fetchMeetings()
            async let pendingUsersResult = try? dataService.fetchPendingUsers()

            let pendingResult = await pending ?? []
            let allResult = await allPosts ?? []
            let meetingsData = await meetingsResult ?? []
            let pendingUsersData = await pendingUsersResult ?? []

            await MainActor.run {
                pendingPosts = pendingResult
                approvedPosts = allResult.filter { $0.status == .approved }

                // Load pending user approvals
                pendingUsers = pendingUsersData
                pendingUserNotifications = pendingUsersData.map { user in
                    PendingUserNotification(user: user, requestedAt: user.createdAt)
                }

                // All users (staff + alumni) — Counselor removed from active care team
                let staff: [User] = [MockData.caseManager, MockData.therapist]
                staffMembers = staff
                alumniUsers = MockData.alumniRoster
                allUsers = alumniUsers + staff

                // Load sobriety notifications (mock)
                loadSobrietyNotifications()

                // Load badge earned notifications (mock)
                loadBadgeNotifications()

                // Check for unread badge notifications and show toast
                checkNewBadgeNotifications()

                // Load staff assignments (multiple per user)
                for assignment in MockData.staffAssignments {
                    staffAssignments[assignment.userId, default: []].append(assignment.staffId)
                }

                // Load content items
                loadContentItems()

                // Load contacts
                companyContacts = MockData.companyContacts
                crisisResources = MockData.crisisResources

                // Load chat monitor
                loadChatMonitorEntries()

                // Load meetings
                meetings = meetingsData

                // Load gamification data
                loadGamificationData()

                // Load announcements
                announcements = MockData.announcements

                isLoading = false
            }
        }
    }

    // MARK: - Sobriety Tracking

    private func loadSobrietyNotifications() {
        // Mock notifications for sobriety date changes
        sobrietyNotifications = [
            SobrietyChangeNotification(
                user: MockData.alumniRoster[0],
                previousDate: Calendar.current.date(byAdding: .day, value: -365, to: Date())!,
                newDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                changedAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
                isRead: false
            ),
            SobrietyChangeNotification(
                user: MockData.alumniRoster[1],
                previousDate: Calendar.current.date(byAdding: .day, value: -200, to: Date())!,
                newDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                changedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                isRead: true
            ),
        ]
    }

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
        Task {
            do {
                let approvedUser = try await dataService.approveUser(userId: userId)
                await MainActor.run {
                    pendingUsers.removeAll { $0.id == userId }
                    pendingUserNotifications.removeAll { $0.user.id == userId }
                    AuditLogger.shared.log(.approveUser, userId: userId, detail: "Approved: \(approvedUser.fullName)")

                    // Notify the user they've been approved
                    PushNotificationService.shared.scheduleLocalNotification(
                        title: "Welcome to Milton Alumni!",
                        body: "Your account has been approved. You can now log in and access the community.",
                        userInfo: ["type": "user_approved", "userId": userId.uuidString]
                    )
                }
            } catch {
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
                #if DEBUG
                print("[AdminViewModel] Failed to reject user: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Refresh just the pending users list (called after push notification tap).
    func refreshPendingUsers() {
        Task {
            let users = (try? await dataService.fetchPendingUsers()) ?? []
            await MainActor.run {
                pendingUsers = users
                pendingUserNotifications = users.map { user in
                    PendingUserNotification(user: user, requestedAt: user.createdAt)
                }
            }
        }
    }

    // MARK: - Badge Notifications

    private func loadBadgeNotifications() {
        // Mock notifications for badge earnings
        let badges = MockData.badges
        badgeNotifications = [
            BadgeEarnedNotification(
                user: MockData.alumniRoster[3],
                badge: badges[0],
                earnedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                isRead: false
            ),
            BadgeEarnedNotification(
                user: MockData.alumniRoster[1],
                badge: badges[2],
                earnedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                isRead: false
            ),
            BadgeEarnedNotification(
                user: MockData.alumniRoster[5],
                badge: badges[4],
                earnedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                isRead: true
            ),
        ]
    }

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

    private func loadContentItems() {
        contentItems = [
            AdminContentItem(
                id: UUID(), title: "Morning Meditation Reminder",
                body: "Take 10 minutes each morning to center yourself. Focus on your breath and set an intention for the day.",
                type: .reflection, isPinned: false,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            ),
            AdminContentItem(
                id: UUID(), title: "New Group Session Starting",
                body: "We are launching a new alumni support group every Wednesday at 6pm. All are welcome!",
                type: .news, isPinned: true,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            ),
            AdminContentItem(
                id: UUID(), title: "Holiday Hours Update",
                body: "Our offices will be closed Dec 25-26. Emergency support line remains available 24/7.",
                type: .pinnedUpdate, isPinned: true,
                createdAt: Date()
            ),
        ]
    }

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

                        // Notify the user their post was rejected
                        notifyPostAuthor(
                            userName: post.userName,
                            title: "Post Not Approved",
                            body: "Your community post didn't meet our community guidelines. Please review the guidelines and try again."
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

    private func loadChatMonitorEntries() {
        let rawEntries: [(alumni: String, staff: String, role: UserRole, message: String, hoursAgo: Int, isDays: Bool, count: Int)] = [
            (MockData.alumniRoster[0].fullName, MockData.caseManager.fullName, .caseManager,
             "I used the breathing exercises from our last session and called my sponsor.", -2, false, 5),
            (MockData.alumniRoster[1].fullName, MockData.therapist.fullName, .therapist,
             "I relapsed last night and I'm feeling hopeless about everything.", -1, false, 12),
            (MockData.alumniRoster[2].fullName, MockData.counselor.fullName, .counselor,
             "Thank you for checking in! Feeling great this week.", -24, true, 8),
            (MockData.alumniRoster[3].fullName, MockData.caseManager.fullName, .caseManager,
             "Can we schedule a call for tomorrow?", -5, false, 3),
        ]

        chatMonitorEntries = rawEntries.map { entry in
            let filterResult = ContentFilterService.shared.localFilter(entry.message)
            let isFlagged = filterResult.status != .clean
            let modStatus: ChatModerationStatus = {
                switch filterResult.status {
                case .crisis: return .denied
                case .flagged: return .flagged
                case .clean: return .none
                }
            }()
            let date = entry.isDays
                ? Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                : Calendar.current.date(byAdding: .hour, value: entry.hoursAgo, to: Date())!

            return ChatMonitorEntry(
                alumniName: entry.alumni,
                staffName: entry.staff,
                staffRole: entry.role,
                lastMessagePreview: entry.message,
                lastMessageAt: date,
                flagged: isFlagged,
                moderationStatus: modStatus,
                messageCount: entry.count
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

        if let existing = editingMeeting,
           let index = meetings.firstIndex(where: { $0.id == existing.id }) {
            meetings[index].title = meetingTitle
            meetings[index].description = meetingDescription.isEmpty ? nil : meetingDescription
            meetings[index].meetingType = meetingType
            meetings[index].date = meetingDate
            meetings[index].startTime = meetingStartTime
            meetings[index].endTime = meetingEndTime
            meetings[index].locationAddress = meetingLocation.isEmpty ? nil : meetingLocation
            meetings[index].virtualLink = meetingVirtualLink.isEmpty ? nil : meetingVirtualLink
            meetings[index].isRecurring = meetingIsRecurring
            meetings[index].recurrencePattern = meetingIsRecurring ? meetingRecurrence : nil
            AuditLogger.shared.log(.updateMeeting, detail: meetingTitle)
        } else {
            let newMeeting = Meeting(
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
                createdBy: MockData.currentUser.id,
                createdAt: Date()
            )
            meetings.insert(newMeeting, at: 0)
            AuditLogger.shared.log(.createMeeting, detail: meetingTitle)
        }
        showingMeetingEditor = false
        editingMeeting = nil
    }

    func deleteMeeting(_ meeting: Meeting) {
        AuditLogger.shared.log(.deleteMeeting, detail: meeting.title)
        meetings.removeAll { $0.id == meeting.id }
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

    // MARK: - Gamification Admin Controls

    private func loadGamificationData() {
        editableBadges = MockData.badges
        editablePointActions = [
            .dailyLogin: PointAction.dailyLogin.points,
            .postCreated: PointAction.postCreated.points,
            .postLiked: PointAction.postLiked.points,
            .milestoneReached: PointAction.milestoneReached.points,
        ]
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
                #if DEBUG
                print("[AdminViewModel] ⚠️ Failed to update flag \(flagId): \(error)")
                #endif
            }
        }
    }
}
