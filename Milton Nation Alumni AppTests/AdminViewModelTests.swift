import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("AdminViewModel Tests")
struct AdminViewModelTests {

    // MARK: - Admin Sections by Role

    @Test("superAdmin sees all sections")
    func superAdminSeesAllSections() {
        let sections = AdminViewModel.AdminSection.sections(for: .superAdmin)
        #expect(sections.count == AdminViewModel.AdminSection.allCases.count)
    }

    @Test("admin sees only admin sections")
    func adminSeesOnlyAdminSections() {
        let sections = AdminViewModel.AdminSection.sections(for: .admin)
        let expected = AdminViewModel.AdminSection.adminSections
        #expect(sections.count == expected.count)
        for section in sections {
            #expect(expected.contains(section))
        }
    }

    @Test("alumni sees no admin sections")
    func alumniSeesNoSections() {
        let sections = AdminViewModel.AdminSection.sections(for: .alumni)
        #expect(sections.isEmpty)
    }

    @Test("superAdmin-only sections not visible to admin")
    func superAdminOnlySectionsHiddenFromAdmin() {
        let adminSections = AdminViewModel.AdminSection.sections(for: .admin)
        let superOnly = AdminViewModel.AdminSection.superAdminOnlySections
        for section in superOnly {
            #expect(!adminSections.contains(section))
        }
    }

    // MARK: - Staff Assignment

    @Test("assignStaff adds a staff member for alumni")
    func assignStaffAdds() {
        let vm = AdminViewModel()
        let alumniId = UUID()
        let staffId = UUID()
        vm.staffMembers = [makeStaffUser(id: staffId, role: .caseManager)]

        vm.assignStaff(alumniId: alumniId, role: .caseManager, staffId: staffId)

        let assigned = vm.staffAssignments[alumniId]
        #expect(assigned?.contains(staffId) == true)
    }

    @Test("assignStaff replaces existing staff of same role")
    func assignStaffReplacesSameRole() {
        let vm = AdminViewModel()
        let alumniId = UUID()
        let oldStaffId = UUID()
        let newStaffId = UUID()
        vm.staffMembers = [
            makeStaffUser(id: oldStaffId, role: .caseManager),
            makeStaffUser(id: newStaffId, role: .caseManager),
        ]

        vm.assignStaff(alumniId: alumniId, role: .caseManager, staffId: oldStaffId)
        vm.assignStaff(alumniId: alumniId, role: .caseManager, staffId: newStaffId)

        let assigned = vm.staffAssignments[alumniId]!
        #expect(!assigned.contains(oldStaffId))
        #expect(assigned.contains(newStaffId))
    }

    @Test("assignStaff with nil removes staff of that role")
    func assignStaffRemoves() {
        let vm = AdminViewModel()
        let alumniId = UUID()
        let staffId = UUID()
        vm.staffMembers = [makeStaffUser(id: staffId, role: .therapist)]

        vm.assignStaff(alumniId: alumniId, role: .therapist, staffId: staffId)
        vm.assignStaff(alumniId: alumniId, role: .therapist, staffId: nil)

        #expect(vm.staffAssignments[alumniId] == nil)
    }

    // MARK: - Content Management

    @Test("beginCreateContent resets editor state")
    func beginCreateContentResetsEditor() {
        let vm = AdminViewModel()
        vm.contentEditorTitle = "Old title"
        vm.contentEditorBody = "Old body"

        vm.beginCreateContent()

        #expect(vm.contentEditorTitle.isEmpty)
        #expect(vm.contentEditorBody.isEmpty)
        #expect(vm.editingContentItem == nil)
        #expect(vm.showingContentEditor == true)
    }

    @Test("saveContent creates new item when no editing item")
    func saveContentCreatesNew() {
        let vm = AdminViewModel()
        vm.beginCreateContent()
        vm.contentEditorTitle = "New Title"
        vm.contentEditorBody = "New Body"
        vm.contentEditorType = .news

        let initialCount = vm.contentItems.count
        vm.saveContent()

        #expect(vm.contentItems.count == initialCount + 1)
        #expect(vm.contentItems.first?.title == "New Title")
        #expect(vm.showingContentEditor == false)
    }

    @Test("saveContent does nothing with empty title")
    func saveContentEmptyTitle() {
        let vm = AdminViewModel()
        vm.beginCreateContent()
        vm.contentEditorTitle = ""
        vm.contentEditorBody = "Body"

        let initialCount = vm.contentItems.count
        vm.saveContent()

        #expect(vm.contentItems.count == initialCount)
    }

    @Test("deleteContent removes the item")
    func deleteContentRemovesItem() {
        let vm = AdminViewModel()
        let item = AdminContentItem(
            id: UUID(), title: "Test", body: "Test body",
            type: .news, isPinned: false, createdAt: Date()
        )
        vm.contentItems = [item]

        vm.deleteContent(item)

        #expect(vm.contentItems.isEmpty)
    }

    @Test("toggleContentPin toggles pin state")
    func toggleContentPin() {
        let vm = AdminViewModel()
        let item = AdminContentItem(
            id: UUID(), title: "Test", body: "Test body",
            type: .news, isPinned: false, createdAt: Date()
        )
        vm.contentItems = [item]

        vm.toggleContentPin(item)

        #expect(vm.contentItems.first?.isPinned == true)
    }

    // MARK: - User Promotion

    @Test("beginPromoteUser sets promotion state")
    func beginPromoteUser() {
        let vm = AdminViewModel()
        let user = makeAlumniUser()

        vm.beginPromoteUser(user, to: .admin)

        #expect(vm.showPromoteConfirmation == true)
        #expect(vm.userToPromote?.id == user.id)
        #expect(vm.selectedPromotionRole == .admin)
    }

    @Test("confirmPromoteUser changes user role")
    func confirmPromoteUser() {
        let vm = AdminViewModel()
        let user = makeAlumniUser()
        vm.alumniUsers = [user]
        vm.allUsers = [user]

        vm.beginPromoteUser(user, to: .admin)
        vm.confirmPromoteUser()

        #expect(vm.alumniUsers.first?.role == .admin)
        #expect(vm.allUsers.first?.role == .admin)
        #expect(vm.showPromoteConfirmation == false)
        #expect(vm.userToPromote == nil)
    }

    @Test("cancelPromotion clears promotion state")
    func cancelPromotion() {
        let vm = AdminViewModel()
        let user = makeAlumniUser()
        vm.beginPromoteUser(user)

        vm.cancelPromotion()

        #expect(vm.showPromoteConfirmation == false)
        #expect(vm.userToPromote == nil)
    }

    // MARK: - Notifications

    @Test("markNotificationRead marks specific notification")
    func markNotificationRead() {
        let vm = AdminViewModel()
        let notification = SobrietyChangeNotification(
            user: makeAlumniUser(),
            previousDate: Date(),
            newDate: Date(),
            changedAt: Date(),
            isRead: false
        )
        vm.sobrietyNotifications = [notification]

        vm.markNotificationRead(notification.id)

        #expect(vm.sobrietyNotifications.first?.isRead == true)
    }

    @Test("markAllNotificationsRead marks all notifications")
    func markAllNotificationsRead() {
        let vm = AdminViewModel()
        vm.sobrietyNotifications = [
            SobrietyChangeNotification(
                user: makeAlumniUser(), previousDate: Date(),
                newDate: Date(), changedAt: Date(), isRead: false
            ),
            SobrietyChangeNotification(
                user: makeAlumniUser(), previousDate: Date(),
                newDate: Date(), changedAt: Date(), isRead: false
            ),
        ]
        vm.badgeNotifications = [
            BadgeEarnedNotification(
                user: makeAlumniUser(),
                badge: Badge(id: UUID(), name: "Test", description: "Test", emoji: "🌱", pointsRequired: 100, sortOrder: 1),
                earnedAt: Date(), isRead: false
            ),
        ]

        vm.markAllNotificationsRead()

        #expect(vm.sobrietyNotifications.filter { !$0.isRead }.isEmpty)
        #expect(vm.badgeNotifications.filter { !$0.isRead }.isEmpty)
    }

    @Test("unreadNotificationCount sums sobriety and badge unread counts")
    func unreadNotificationCount() {
        let vm = AdminViewModel()
        vm.sobrietyNotifications = [
            SobrietyChangeNotification(
                user: makeAlumniUser(), previousDate: Date(),
                newDate: Date(), changedAt: Date(), isRead: false
            ),
            SobrietyChangeNotification(
                user: makeAlumniUser(), previousDate: Date(),
                newDate: Date(), changedAt: Date(), isRead: true
            ),
        ]
        vm.badgeNotifications = [
            BadgeEarnedNotification(
                user: makeAlumniUser(),
                badge: Badge(id: UUID(), name: "Test", description: "Test", emoji: "🌱", pointsRequired: 100, sortOrder: 1),
                earnedAt: Date(), isRead: false
            ),
        ]

        #expect(vm.unreadNotificationCount == 2) // 1 sobriety + 1 badge
    }

    // MARK: - Chat Moderation

    @Test("allowFlaggedMessage clears flag and sets allowed status")
    func allowFlaggedMessage() {
        let vm = AdminViewModel()
        let entry = ChatMonitorEntry(
            alumniName: "Test", staffName: "Staff", staffRole: .caseManager,
            lastMessagePreview: "Message", lastMessageAt: Date(),
            flagged: true, moderationStatus: .flagged, messageCount: 1
        )
        vm.chatMonitorEntries = [entry]

        vm.allowFlaggedMessage(entry.id)

        #expect(vm.chatMonitorEntries.first?.flagged == false)
        #expect(vm.chatMonitorEntries.first?.moderationStatus == .allowed)
        #expect(vm.showModerationModal == false)
    }

    @Test("denyFlaggedMessage sets denied status and keeps flagged")
    func denyFlaggedMessage() {
        let vm = AdminViewModel()
        let entry = ChatMonitorEntry(
            alumniName: "Test", staffName: "Staff", staffRole: .caseManager,
            lastMessagePreview: "Message", lastMessageAt: Date(),
            flagged: true, moderationStatus: .flagged, messageCount: 1
        )
        vm.chatMonitorEntries = [entry]

        vm.denyFlaggedMessage(entry.id)

        #expect(vm.chatMonitorEntries.first?.flagged == true)
        #expect(vm.chatMonitorEntries.first?.moderationStatus == .denied)
    }

    // MARK: - Filtered Alumni Search

    @Test("filteredAlumni returns all when search is empty")
    func filteredAlumniEmpty() {
        let vm = AdminViewModel()
        vm.alumniUsers = [makeAlumniUser(fullName: "Alice"), makeAlumniUser(fullName: "Bob")]
        vm.sobrietySearchText = ""
        #expect(vm.filteredAlumni.count == 2)
    }

    @Test("filteredAlumni filters by name case-insensitively")
    func filteredAlumniByName() {
        let vm = AdminViewModel()
        vm.alumniUsers = [makeAlumniUser(fullName: "Alice Smith"), makeAlumniUser(fullName: "Bob Jones")]
        vm.sobrietySearchText = "alice"
        #expect(vm.filteredAlumni.count == 1)
        #expect(vm.filteredAlumni.first?.fullName == "Alice Smith")
    }

    // MARK: - Meeting Management

    @Test("beginCreateMeeting resets editor state")
    func beginCreateMeetingResetsEditor() {
        let vm = AdminViewModel()
        vm.meetingTitle = "Old Meeting"
        vm.beginCreateMeeting()

        #expect(vm.meetingTitle.isEmpty)
        #expect(vm.editingMeeting == nil)
        #expect(vm.showingMeetingEditor == true)
    }

    @Test("saveMeeting creates new meeting")
    func saveMeetingCreatesNew() {
        let vm = AdminViewModel()
        vm.beginCreateMeeting()
        vm.meetingTitle = "New Meeting"
        vm.meetingDescription = "A test meeting"
        vm.meetingType = .virtual

        let initialCount = vm.meetings.count
        vm.saveMeeting()

        #expect(vm.meetings.count == initialCount + 1)
        #expect(vm.meetings.first?.title == "New Meeting")
    }

    @Test("saveMeeting does nothing with empty title")
    func saveMeetingEmptyTitle() {
        let vm = AdminViewModel()
        vm.beginCreateMeeting()
        vm.meetingTitle = ""

        let initialCount = vm.meetings.count
        vm.saveMeeting()

        #expect(vm.meetings.count == initialCount)
    }

    @Test("deleteMeeting removes the meeting")
    func deleteMeetingRemoves() {
        let vm = AdminViewModel()
        let meeting = Meeting(
            id: UUID(), title: "Test", description: nil, meetingType: .virtual,
            date: Date(), startTime: Date(), endTime: Date(), locationAddress: nil,
            locationLat: nil, locationLng: nil, virtualLink: nil,
            isRecurring: false, recurrencePattern: nil, recurrenceEndDate: nil,
            parentMeetingId: nil, createdBy: UUID(), createdAt: Date()
        )
        vm.meetings = [meeting]

        vm.deleteMeeting(meeting)

        #expect(vm.meetings.isEmpty)
    }

    // MARK: - Contact Management

    @Test("addNewContact appends a new contact and starts editing")
    func addNewContact() {
        let vm = AdminViewModel()
        let initialCount = vm.companyContacts.count

        vm.addNewContact()

        #expect(vm.companyContacts.count == initialCount + 1)
        #expect(vm.editingContactId != nil)
    }

    @Test("deleteContact removes the contact")
    func deleteContact() {
        let vm = AdminViewModel()
        let contact = CompanyContact(name: "Test", phoneNumber: "(555) 000-0000", role: nil)
        vm.companyContacts = [contact]

        vm.deleteContact(contact)

        #expect(vm.companyContacts.isEmpty)
    }

    // MARK: - Chat Monitoring (real flagged messages)

    /// The chat monitor is now built from REAL flagged/crisis messages fetched
    /// from Supabase (no fabricated fake crisis lines — that mock data was
    /// removed as a launch blocker). This tests the pure builder that maps real
    /// `ChatMessage` rows into monitor entries.
    @Test("buildChatMonitorEntries maps real flagged messages and marks crisis as denied")
    func chatMonitorBuildsFromRealMessages() {
        let member = User.placeholder(id: UUID(), fullName: "Real Member")
        let convId = UUID()

        let flagged = ChatMessage(
            id: UUID(), conversationId: convId, senderId: member.id,
            messageType: .text, content: "I'm really struggling today",
            status: .flagged, createdAt: Date()
        )
        let crisis = ChatMessage(
            id: UUID(), conversationId: convId, senderId: member.id,
            messageType: .text, content: "crisis content",
            status: .flaggedForCrisis, createdAt: Date()
        )

        let entries = AdminViewModel.buildChatMonitorEntries(
            from: [flagged, crisis],
            alumni: [member],
            staff: []
        )

        // Every entry from fetchFlaggedMessages is, by definition, flagged.
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.flagged })
        // Crisis-status messages surface as denied; plain flagged as flagged.
        #expect(entries.contains { $0.moderationStatus == .denied })
        #expect(entries.contains { $0.moderationStatus == .flagged })
        // Sender name resolves from the roster.
        #expect(entries.allSatisfy { $0.alumniName == "Real Member" })
    }

    @Test("buildChatMonitorEntries returns empty for no flagged messages")
    func chatMonitorEmptyWhenNoneFlagged() {
        let entries = AdminViewModel.buildChatMonitorEntries(from: [], alumni: [], staff: [])
        #expect(entries.isEmpty)
    }

    @Test("showFlaggedChatOnly toggle filters chat entries correctly")
    func showFlaggedChatOnlyFilters() {
        let vm = AdminViewModel()
        // Seed entries directly (no dependency on network/mock fetch).
        let member = User.placeholder(id: UUID(), fullName: "Member")
        let msg = ChatMessage(
            id: UUID(), conversationId: UUID(), senderId: member.id,
            messageType: .text, content: "flagged content",
            status: .flagged, createdAt: Date()
        )
        vm.chatMonitorEntries = AdminViewModel.buildChatMonitorEntries(
            from: [msg], alumni: [member], staff: []
        )

        let totalCount = vm.chatMonitorEntries.count
        let flaggedCount = vm.chatMonitorEntries.filter { $0.flagged }.count

        vm.showFlaggedChatOnly = true
        let filteredEntries = vm.filteredChatEntries
        #expect(filteredEntries.count == flaggedCount)
        #expect(filteredEntries.count <= totalCount)
    }

    // MARK: - RSVP Tracking (Feature #7)

    @Test("Meeting rsvpUserIds defaults to empty")
    func meetingRSVPDefaultsEmpty() {
        let meeting = Meeting(
            id: UUID(), title: "Test Meeting", description: nil, meetingType: .virtual,
            date: Date(), startTime: Date(), endTime: Date(), locationAddress: nil,
            locationLat: nil, locationLng: nil, virtualLink: nil,
            isRecurring: false, recurrencePattern: nil, recurrenceEndDate: nil,
            parentMeetingId: nil, createdBy: UUID(), createdAt: Date()
        )
        #expect(meeting.rsvpUserIds.isEmpty)
    }

    @Test("Meeting rsvpUserIds stores user IDs")
    func meetingRSVPStoresIds() {
        let userId1 = UUID()
        let userId2 = UUID()
        let meeting = Meeting(
            id: UUID(), title: "Test Meeting", description: nil, meetingType: .inPerson,
            date: Date(), startTime: Date(), endTime: Date(), locationAddress: "123 Main St",
            locationLat: nil, locationLng: nil, virtualLink: nil,
            isRecurring: false, recurrencePattern: nil, recurrenceEndDate: nil,
            parentMeetingId: nil, createdBy: UUID(), createdAt: Date(),
            rsvpUserIds: [userId1, userId2]
        )
        #expect(meeting.rsvpUserIds.count == 2)
        #expect(meeting.rsvpUserIds.contains(userId1))
        #expect(meeting.rsvpUserIds.contains(userId2))
    }

    @Test("rsvpUsers returns matching alumni from roster")
    func rsvpUsersReturnsMatchingAlumni() {
        let vm = AdminViewModel()
        let user1 = makeAlumniUser(fullName: "RSVP User 1")
        let user2 = makeAlumniUser(fullName: "RSVP User 2")
        let user3 = makeAlumniUser(fullName: "Non-RSVP User")
        vm.alumniUsers = [user1, user2, user3]

        let meeting = Meeting(
            id: UUID(), title: "Test Meeting", description: nil, meetingType: .virtual,
            date: Date(), startTime: Date(), endTime: Date(), locationAddress: nil,
            locationLat: nil, locationLng: nil, virtualLink: nil,
            isRecurring: false, recurrencePattern: nil, recurrenceEndDate: nil,
            parentMeetingId: nil, createdBy: UUID(), createdAt: Date(),
            rsvpUserIds: [user1.id, user2.id]
        )

        let rsvpUsers = vm.rsvpUsers(for: meeting)
        #expect(rsvpUsers.count == 2)
        #expect(rsvpUsers.contains(where: { $0.fullName == "RSVP User 1" }))
        #expect(rsvpUsers.contains(where: { $0.fullName == "RSVP User 2" }))
        #expect(!rsvpUsers.contains(where: { $0.fullName == "Non-RSVP User" }))
    }

    @Test("selectedRSVPMeeting and showRSVPSheet default state")
    func rsvpSheetDefaultState() {
        let vm = AdminViewModel()
        #expect(vm.selectedRSVPMeeting == nil)
        #expect(vm.showRSVPSheet == false)
    }

    // MARK: - Badge Toast (Feature #2)

    @Test("showBadgeToast and badgeToastMessage default state")
    func badgeToastDefaultState() {
        let vm = AdminViewModel()
        #expect(vm.showBadgeToast == false)
        #expect(vm.badgeToastMessage.isEmpty)
    }

    @Test("checkNewBadgeNotifications sets toast message when unread badges exist")
    func checkNewBadgeNotificationsShowsToast() async throws {
        let vm = AdminViewModel()
        vm.badgeNotifications = [
            BadgeEarnedNotification(
                user: makeAlumniUser(fullName: "Alice"),
                badge: Badge(id: UUID(), name: "First Step", description: "Test", emoji: "🌱", pointsRequired: 100, sortOrder: 1),
                earnedAt: Date(), isRead: false
            ),
        ]

        vm.checkNewBadgeNotifications()

        // Toast message is set synchronously
        #expect(!vm.badgeToastMessage.isEmpty)
        #expect(vm.badgeToastMessage.contains("Alice"))
        #expect(vm.badgeToastMessage.contains("First Step"))

        // showBadgeToast is set via DispatchQueue.main.asyncAfter(0.5s), wait for it
        try await Task.sleep(for: .milliseconds(800))
        #expect(vm.showBadgeToast == true)
    }

    @Test("checkNewBadgeNotifications does nothing when all badges are read")
    func checkNewBadgeNotificationsNoUnread() {
        let vm = AdminViewModel()
        vm.badgeNotifications = [
            BadgeEarnedNotification(
                user: makeAlumniUser(fullName: "Alice"),
                badge: Badge(id: UUID(), name: "First Step", description: "Test", emoji: "🌱", pointsRequired: 100, sortOrder: 1),
                earnedAt: Date(), isRead: true
            ),
        ]

        vm.checkNewBadgeNotifications()

        #expect(vm.showBadgeToast == false)
        #expect(vm.badgeToastMessage.isEmpty)
    }

    // MARK: - SobrietyChangeNotification

    @Test("wasReset returns true when new date is after previous date")
    func wasResetTrue() {
        let notification = SobrietyChangeNotification(
            user: makeAlumniUser(),
            previousDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
            newDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            changedAt: Date()
        )
        #expect(notification.wasReset == true)
    }

    @Test("wasReset returns false when new date is before previous date")
    func wasResetFalse() {
        let notification = SobrietyChangeNotification(
            user: makeAlumniUser(),
            previousDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            newDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
            changedAt: Date()
        )
        #expect(notification.wasReset == false)
    }

    // MARK: - Helpers

    private func makeStaffUser(id: UUID = UUID(), role: UserRole) -> User {
        User(
            id: id, email: "staff@example.com", phone: "(555) 000-0000",
            fullName: "Staff Member", username: "staff_member",
            profilePhotoURL: nil, sobrietyDate: Date(), dischargeDate: Date(),
            recoveryProgram: "", role: role, status: .active,
            mfaMethod: .email, totalPoints: 0, lastLogin: nil,
            lastPointsAwarded: nil, createdAt: Date(), updatedAt: Date()
        )
    }

    private func makeAlumniUser(fullName: String = "Test Alumni") -> User {
        User(
            id: UUID(), email: "alumni@example.com", phone: "(555) 000-0000",
            fullName: fullName, username: "test_alumni",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -95, to: Date())!,
            recoveryProgram: "Test", role: .alumni, status: .active,
            mfaMethod: nil, totalPoints: 0, lastLogin: nil,
            lastPointsAwarded: nil, createdAt: Date(), updatedAt: Date()
        )
    }
}
