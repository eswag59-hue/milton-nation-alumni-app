import Foundation

enum PointAction: String, Codable, CaseIterable {
    case dailyLogin
    case postCreated
    case postLiked
    case milestoneReached

    var points: Int {
        switch self {
        case .dailyLogin: return 10
        case .postCreated: return 15
        case .postLiked: return 5
        case .milestoneReached: return 50
        }
    }

    var displayName: String {
        switch self {
        case .dailyLogin: return "Daily Login"
        case .postCreated: return "Community Post"
        case .postLiked: return "Give Support (Like)"
        case .milestoneReached: return "Sobriety Milestone"
        }
    }
}

struct Badge: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var emoji: String
    var pointsRequired: Int
    var sortOrder: Int
}

struct UserBadge: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let badgeId: UUID
    var earnedAt: Date
}

struct SobrietyMilestone: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var milestoneType: MilestoneType
    var milestoneDate: Date
    var pointsAwarded: Int
    var createdAt: Date

    enum MilestoneType: String, Codable {
        case thirtyDays = "30_days"
        case sixtyDays = "60_days"
        case ninetyDays = "90_days"
        case sixMonths = "6_months"
        case oneYear = "1_year"
        case yearly

        var displayName: String {
            switch self {
            case .thirtyDays: return "30 Days"
            case .sixtyDays: return "60 Days"
            case .ninetyDays: return "90 Days"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            case .yearly: return "Anniversary"
            }
        }

        var points: Int {
            switch self {
            case .thirtyDays: return 50
            case .sixtyDays: return 75
            case .ninetyDays: return 100
            case .sixMonths: return 150
            case .oneYear: return 250
            case .yearly: return 250
            }
        }
    }
}
