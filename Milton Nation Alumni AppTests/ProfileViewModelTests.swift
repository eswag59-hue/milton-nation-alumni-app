import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("ProfileViewModel Tests")
struct ProfileViewModelTests {

    // MARK: - Days Since Admission

    @Test("daysSinceAdmission calculates correctly")
    func daysSinceAdmission() {
        let dischargeDate = Calendar.current.date(byAdding: .day, value: -50, to: Date())!
        let user = makeUser(dischargeDate: dischargeDate)
        let vm = ProfileViewModel(user: user)
        #expect(vm.daysSinceAdmission == 50)
    }

    @Test("daysSinceAdmission returns 0 for today")
    func daysSinceAdmissionToday() {
        let user = makeUser(dischargeDate: Date())
        let vm = ProfileViewModel(user: user)
        #expect(vm.daysSinceAdmission == 0)
    }

    // MARK: - Next Badge

    @Test("nextBadge returns first badge above current points")
    func nextBadgeAbovePoints() {
        let user = makeUser(totalPoints: 150)
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        let next = vm.nextBadge
        #expect(next?.pointsRequired == 250)
    }

    @Test("nextBadge returns nil when user has all badges")
    func nextBadgeNilWhenAllEarned() {
        let user = makeUser(totalPoints: 10000)
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        #expect(vm.nextBadge == nil)
    }

    @Test("nextBadge returns first badge when user has 0 points")
    func nextBadgeZeroPoints() {
        let user = makeUser(totalPoints: 0)
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        #expect(vm.nextBadge?.pointsRequired == 100)
    }

    // MARK: - Progress to Next Badge

    @Test("progressToNextBadge returns correct fraction")
    func progressToNextBadgeFraction() {
        let user = makeUser(totalPoints: 175) // Between 100 and 250
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        // Progress from 100 to 250: (175-100) / (250-100) = 75/150 = 0.5
        let progress = vm.progressToNextBadge
        #expect(progress > 0.49 && progress < 0.51)
    }

    @Test("progressToNextBadge returns 1.0 when all badges earned")
    func progressComplete() {
        let user = makeUser(totalPoints: 10000)
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        #expect(vm.progressToNextBadge == 1.0)
    }

    @Test("progressToNextBadge handles zero points correctly")
    func progressZeroPoints() {
        let user = makeUser(totalPoints: 0)
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        // Progress from 0 to 100: 0/100 = 0.0
        #expect(vm.progressToNextBadge == 0.0)
    }

    @Test("progressToNextBadge at exact badge threshold")
    func progressAtExactThreshold() {
        let user = makeUser(totalPoints: 100) // Exactly at "Seedling"
        let vm = ProfileViewModel(user: user)
        vm.badges = makeBadges()

        // Next badge is 250, previous earned is 100
        // Progress: (100-100) / (250-100) = 0/150 = 0.0
        #expect(vm.progressToNextBadge == 0.0)
    }

    // MARK: - Helpers

    private func makeBadges() -> [Badge] {
        [
            Badge(id: UUID(), name: "Seedling", description: "100 pts", emoji: "🌱", pointsRequired: 100, sortOrder: 1),
            Badge(id: UUID(), name: "Sprout", description: "250 pts", emoji: "🌿", pointsRequired: 250, sortOrder: 2),
            Badge(id: UUID(), name: "Bloom", description: "500 pts", emoji: "🌸", pointsRequired: 500, sortOrder: 3),
            Badge(id: UUID(), name: "Tree", description: "1000 pts", emoji: "🌳", pointsRequired: 1000, sortOrder: 4),
        ]
    }

    private func makeUser(
        totalPoints: Int = 0,
        dischargeDate: Date = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
    ) -> User {
        User(
            id: UUID(),
            email: "test@example.com",
            phone: "(555) 000-0000",
            fullName: "Test User",
            username: "test_user",
            profilePhotoURL: nil,
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
            dischargeDate: dischargeDate,
            recoveryProgram: "Test",
            role: .alumni,
            status: .active,
            mfaMethod: nil,
            totalPoints: totalPoints,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
