import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("User Model Tests")
struct UserTests {

    // MARK: - Sobriety Calculations

    @Test("daysOfRecovery returns correct count for known date")
    func daysOfRecoveryKnownDate() {
        let daysAgo = 100
        let user = makeUser(sobrietyDaysAgo: daysAgo)
        #expect(user.daysOfRecovery == daysAgo)
    }

    @Test("daysOfRecovery returns 0 for today")
    func daysOfRecoveryToday() {
        let user = makeUser(sobrietyDaysAgo: 0)
        #expect(user.daysOfRecovery == 0)
    }

    @Test("daysOfRecovery returns 1 for yesterday")
    func daysOfRecoveryYesterday() {
        let user = makeUser(sobrietyDaysAgo: 1)
        #expect(user.daysOfRecovery == 1)
    }

    @Test("weeksOfRecovery is days divided by 7")
    func weeksOfRecoveryCalculation() {
        let user = makeUser(sobrietyDaysAgo: 21)
        #expect(user.weeksOfRecovery == 3)
    }

    @Test("weeksOfRecovery truncates partial weeks")
    func weeksOfRecoveryTruncates() {
        let user = makeUser(sobrietyDaysAgo: 13)
        #expect(user.weeksOfRecovery == 1)
    }

    @Test("monthsOfRecovery for roughly 3 months")
    func monthsOfRecoveryThreeMonths() {
        let sobrietyDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let user = makeUser(sobrietyDate: sobrietyDate)
        #expect(user.monthsOfRecovery == 3)
    }

    @Test("yearsOfRecovery for roughly 2 years")
    func yearsOfRecoveryTwoYears() {
        let sobrietyDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let user = makeUser(sobrietyDate: sobrietyDate)
        #expect(user.yearsOfRecovery == 2)
    }

    @Test("yearsOfRecovery returns 0 for less than a year")
    func yearsOfRecoveryLessThanOne() {
        let user = makeUser(sobrietyDaysAgo: 200)
        #expect(user.yearsOfRecovery == 0)
    }

    // MARK: - Computed Properties

    @Test("firstName extracts first word of fullName")
    func firstNameExtraction() {
        let user = makeUser(fullName: "John Smith")
        #expect(user.firstName == "John")
    }

    @Test("firstName returns full name when no space")
    func firstNameSingleWord() {
        let user = makeUser(fullName: "Madonna")
        #expect(user.firstName == "Madonna")
    }

    // MARK: - UserRole

    @Test("isStaff returns true for clinical and admin roles",
          arguments: [UserRole.caseManager, .therapist, .counselor, .admin, .superAdmin])
    func isStaffTrue(role: UserRole) {
        #expect(role.isStaff == true)
    }

    @Test("isStaff returns false for alumni")
    func isStaffFalseForAlumni() {
        #expect(UserRole.alumni.isStaff == false)
    }

    @Test("isClinical returns true only for clinical roles",
          arguments: [UserRole.caseManager, .therapist, .counselor])
    func isClinicalTrue(role: UserRole) {
        #expect(role.isClinical == true)
    }

    @Test("isClinical returns false for non-clinical roles",
          arguments: [UserRole.alumni, .admin, .superAdmin])
    func isClinicalFalse(role: UserRole) {
        #expect(role.isClinical == false)
    }

    @Test("isAdmin returns true only for admin and superAdmin",
          arguments: [UserRole.admin, .superAdmin])
    func isAdminTrue(role: UserRole) {
        #expect(role.isAdmin == true)
    }

    @Test("isAdmin returns false for non-admin roles",
          arguments: [UserRole.alumni, .caseManager, .therapist, .counselor])
    func isAdminFalse(role: UserRole) {
        #expect(role.isAdmin == false)
    }

    @Test("isSuperAdmin returns true only for superAdmin")
    func isSuperAdminOnly() {
        #expect(UserRole.superAdmin.isSuperAdmin == true)
        #expect(UserRole.admin.isSuperAdmin == false)
        #expect(UserRole.alumni.isSuperAdmin == false)
    }

    @Test("displayName is correct for all roles")
    func displayNames() {
        #expect(UserRole.alumni.displayName == "Alumni")
        #expect(UserRole.caseManager.displayName == "Case Manager")
        #expect(UserRole.therapist.displayName == "Therapist")
        #expect(UserRole.counselor.displayName == "Counselor")
        #expect(UserRole.admin.displayName == "Admin")
        #expect(UserRole.superAdmin.displayName == "Super Admin")
    }

    // MARK: - Helpers

    private func makeUser(
        sobrietyDaysAgo: Int = 100,
        fullName: String = "Test User"
    ) -> User {
        let sobrietyDate = Calendar.current.date(byAdding: .day, value: -sobrietyDaysAgo, to: Date())!
        return makeUser(sobrietyDate: sobrietyDate, fullName: fullName)
    }

    private func makeUser(
        sobrietyDate: Date,
        fullName: String = "Test User"
    ) -> User {
        User(
            id: UUID(),
            email: "test@example.com",
            phone: "(555) 000-0000",
            fullName: fullName,
            username: "test_user",
            profilePhotoURL: nil,
            sobrietyDate: sobrietyDate,
            dischargeDate: Date(),
            recoveryProgram: "Test",
            role: .alumni,
            status: .active,
            mfaMethod: nil,
            totalPoints: 0,
            lastLogin: nil,
            lastPointsAwarded: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
