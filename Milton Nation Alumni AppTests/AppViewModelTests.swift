import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("AppViewModel Tests")
struct AppViewModelTests {

    // MARK: - Login

    @Test("login sets authenticated state correctly")
    func loginSetsState() {
        let vm = AppViewModel()
        let user = makeUser()
        vm.login(user: user)

        #expect(vm.isAuthenticated == true)
        #expect(vm.currentUser != nil)
        #expect(vm.currentUser?.id == user.id)
        #expect(vm.selectedTab == .home)
        #expect(vm.showSobrietyCheck == true)
    }

    // MARK: - Logout

    @Test("logout clears all state")
    func logoutClearsState() async throws {
        let vm = AppViewModel()
        let user = makeUser()
        vm.login(user: user)
        vm.isStrugglingMode = true

        vm.logout()
        // Give the Task time to complete
        try await Task.sleep(for: .milliseconds(1200))

        #expect(vm.isAuthenticated == false)
        #expect(vm.currentUser == nil)
        #expect(vm.isStrugglingMode == false)
        #expect(vm.selectedTab == .home)
        #expect(vm.showSobrietyCheck == false)
    }

    // MARK: - Struggle Mode

    @Test("enterStrugglingMode sets flag and switches to chat tab")
    func enterStrugglingMode() {
        let vm = AppViewModel()
        vm.login(user: makeUser())

        vm.enterStrugglingMode()

        #expect(vm.isStrugglingMode == true)
        #expect(vm.selectedTab == .chat)
    }

    @Test("exitStrugglingMode clears flag")
    func exitStrugglingMode() {
        let vm = AppViewModel()
        vm.login(user: makeUser())
        vm.enterStrugglingMode()

        vm.exitStrugglingMode()

        #expect(vm.isStrugglingMode == false)
    }

    // MARK: - Sobriety Reset

    @Test("resetSobrietyDate updates current user's sobriety date")
    func resetSobrietyDate() {
        let vm = AppViewModel()
        let user = makeUser()
        vm.login(user: user)

        let newDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        vm.resetSobrietyDate(to: newDate)

        #expect(vm.currentUser?.sobrietyDate == newDate)
    }

    @Test("resetSobrietyDate does nothing when not logged in")
    func resetSobrietyDateNoUser() {
        let vm = AppViewModel()
        vm.resetSobrietyDate(to: Date())
        #expect(vm.currentUser == nil)
    }

    // MARK: - Daily Login Points Deduplication

    @Test("login awards points when no previous points awarded")
    func loginAwardsPointsFirstTime() async throws {
        let vm = AppViewModel()
        var user = makeUser()
        user.lastPointsAwarded = nil
        vm.login(user: user)

        // Give the async point award time to process
        try await Task.sleep(for: .milliseconds(1200))

        // Points should have been updated (original was 0, dailyLogin adds 10)
        #expect(vm.currentUser?.totalPoints ?? 0 > 0)
    }

    @Test("login does not double-award points if already awarded today")
    func loginDoesNotDoubleAward() async throws {
        let vm = AppViewModel()
        var user = makeUser()
        user.lastPointsAwarded = Date() // Already awarded today
        user.totalPoints = 100
        vm.login(user: user)

        // Give any async work time
        try await Task.sleep(for: .milliseconds(1200))

        // Points should remain the same since we already got them today
        #expect(vm.currentUser?.totalPoints == 100)
    }

    // MARK: - AppTab

    @Test("AppTab has correct icon names")
    func appTabIcons() {
        #expect(AppTab.home.iconName == "house.fill")
        #expect(AppTab.community.iconName == "person.2.fill")
        #expect(AppTab.meetings.iconName == "calendar")
        #expect(AppTab.chat.iconName == "message.fill")
        #expect(AppTab.profile.iconName == "person.circle.fill")
    }

    // MARK: - Helpers

    private func makeUser() -> User {
        User(
            id: UUID(),
            email: "test@example.com",
            phone: "(555) 000-0000",
            fullName: "Test User",
            username: "test_user",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
            dischargeDate: Calendar.current.date(byAdding: .day, value: -95, to: Date())!,
            recoveryProgram: "Test Program",
            role: .alumni,
            status: .active,
            mfaMethod: .sms,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
