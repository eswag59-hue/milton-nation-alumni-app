import Foundation

enum UserRole: String, Codable, CaseIterable {
    case alumni
    case caseManager = "case_manager"
    case therapist
    case counselor
    case admin
    case superAdmin = "super_admin"

    var displayName: String {
        switch self {
        case .alumni: return "Alumni"
        case .caseManager: return "Case Manager"
        case .therapist: return "Therapist"
        case .counselor: return "Counselor"
        case .admin: return "Admin"
        case .superAdmin: return "Super Admin"
        }
    }

    var isStaff: Bool {
        switch self {
        case .caseManager, .therapist, .counselor, .admin, .superAdmin: return true
        case .alumni: return false
        }
    }

    var isClinical: Bool {
        switch self {
        case .caseManager, .therapist, .counselor: return true
        case .alumni, .admin, .superAdmin: return false
        }
    }

    /// Whether this role can access the admin dashboard
    var isAdmin: Bool {
        switch self {
        case .admin, .superAdmin: return true
        default: return false
        }
    }

    /// Whether this role has full unrestricted access
    var isSuperAdmin: Bool {
        self == .superAdmin
    }
}

enum UserStatus: String, Codable {
    case pending, active, rejected, deactivated, deleted
}

enum MFAMethod: String, Codable {
    case sms, email, totp
}

/// The recovery facility a user belongs to. Determines which community content they see.
enum Facility: String, Codable, CaseIterable, Identifiable {
    case florida = "florida"
    case ohio    = "ohio"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .florida: return "Florida"
        case .ohio:    return "Ohio"
        }
    }

    var emoji: String {
        switch self {
        case .florida: return "🌴"
        case .ohio:    return "🌻"
        }
    }

    /// Support phone number for this facility.
    var supportPhone: String {
        switch self {
        case .florida: return "(844) 406-4325"
        case .ohio:    return "(844) 406-4325"   // Update if Ohio has a separate support line
        }
    }

    /// Facility team display name used in chat and support screens.
    var teamName: String {
        switch self {
        case .florida: return "Milton Team Florida"
        case .ohio:    return "Milton Team Ohio"
        }
    }
}

struct User: Identifiable, Codable, Hashable {
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: UUID
    var email: String
    var phone: String
    var fullName: String
    var username: String
    var profilePhotoURL: String?
    var sobrietyDate: Date
    var dischargeDate: Date
    var recoveryProgram: String
    var role: UserRole
    var status: UserStatus
    var mfaMethod: MFAMethod?
    var totalPoints: Int
    var approvedPostCount: Int = 0
    /// The facility this user belongs to. `nil` means the account is pending admin assignment.
    var facility: Facility? = nil
    /// For admin/staff roles: the facility they are assigned to manage. `nil` for super_admin (manages all).
    var adminFacility: Facility? = nil
    var lastLogin: Date?
    var lastPointsAwarded: Date?
    var createdAt: Date
    var updatedAt: Date

    // Explicit CodingKeys are required because Swift's `.convertFromSnakeCase` strategy
    // lowercases the final component of an acronym: "profile_photo_url" → "profilePhotoUrl"
    // (lowercase 'l'), which does NOT match the Swift property "profilePhotoURL" (uppercase 'L').
    // By specifying the raw value for URL-suffixed keys we bridge that gap while letting all
    // other snake_case fields decode automatically via the strategy.
    enum CodingKeys: String, CodingKey {
        case id, email, phone, username, role, status, facility
        case fullName           // "full_name"        → "fullName"
        case profilePhotoURL = "profilePhotoUrl"  // "profile_photo_url" → "profilePhotoUrl"
        case sobrietyDate       // "sobriety_date"    → "sobrietyDate"
        case dischargeDate      // "discharge_date"   → "dischargeDate"
        case recoveryProgram    // "recovery_program" → "recoveryProgram"
        case mfaMethod          // "mfa_method"       → "mfaMethod"
        case totalPoints        // "total_points"     → "totalPoints"
        case approvedPostCount  // "approved_post_count" → "approvedPostCount"
        case adminFacility      // "admin_facility"   → "adminFacility"
        case lastLogin          // "last_login"       → "lastLogin"
        case lastPointsAwarded  // "last_points_awarded" → "lastPointsAwarded"
        case createdAt          // "created_at"       → "createdAt"
        case updatedAt          // "updated_at"       → "updatedAt"
    }

    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }

    var daysOfRecovery: Int {
        Calendar.current.dateComponents([.day], from: sobrietyDate, to: Date()).day ?? 0
    }

    var weeksOfRecovery: Int {
        daysOfRecovery / 7
    }

    var monthsOfRecovery: Int {
        Calendar.current.dateComponents([.month], from: sobrietyDate, to: Date()).month ?? 0
    }

    var yearsOfRecovery: Int {
        Calendar.current.dateComponents([.year], from: sobrietyDate, to: Date()).year ?? 0
    }
}

struct StaffAssignment: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let staffId: UUID
    let roleType: UserRole
    var assignedAt: Date
}
