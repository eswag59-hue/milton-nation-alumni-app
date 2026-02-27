import Foundation

// MARK: - ContentFlag

/// A record of flagged content stored in the `content_flags` Supabase table.
///
/// IMPORTANT: This model NEVER contains raw user text.
/// Only `redactedSummary` (category labels + counts) is stored.
struct ContentFlag: Identifiable, Codable, Sendable {

    let id: UUID
    let userId: UUID?
    let riskLevel: ContentRiskLevel
    let categories: [ContentCategory]
    let feature: ContentFeature
    let redactedSummary: String   // e.g. "high_risk:self_harm,drugs:3_matches"
    let isEmergency: Bool
    let timestamp: Date
    var reviewStatus: ReviewStatus
    var reviewedBy: UUID?
    var reviewNote: String?

    // MARK: - Review Status

    enum ReviewStatus: String, Codable, CaseIterable, Sendable {
        case pending    = "pending"
        case reviewed   = "reviewed"
        case dismissed  = "dismissed"
        case escalated  = "escalated"

        var displayName: String {
            switch self {
            case .pending:   return "Pending Review"
            case .reviewed:  return "Reviewed"
            case .dismissed: return "Dismissed"
            case .escalated: return "Escalated"
            }
        }

        var color: String {
            switch self {
            case .pending:   return "orange"
            case .reviewed:  return "green"
            case .dismissed: return "gray"
            case .escalated: return "red"
            }
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId          = "user_id"
        case riskLevel       = "risk_level"
        case categories
        case feature
        case redactedSummary = "redacted_summary"
        case isEmergency     = "is_emergency"
        case timestamp
        case reviewStatus    = "review_status"
        case reviewedBy      = "reviewed_by"
        case reviewNote      = "review_note"
    }

    // MARK: - Display Helpers

    var riskColor: String {
        switch riskLevel {
        case .safe:       return "green"
        case .lowRisk:    return "yellow"
        case .mediumRisk: return "orange"
        case .highRisk:   return "red"
        }
    }

    var primaryCategory: ContentCategory? { categories.first }

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - ContentFlagFilter (for admin dashboard queries)

struct ContentFlagFilter: Sendable {
    var riskLevels: Set<ContentRiskLevel>       = Set(ContentRiskLevel.allCases)
    var categories: Set<ContentCategory>        = Set(ContentCategory.allCases)
    var reviewStatuses: Set<ContentFlag.ReviewStatus> = Set(ContentFlag.ReviewStatus.allCases)
    var dateRange: ClosedRange<Date>?

    static let showAll = ContentFlagFilter()
    static let pendingOnly = ContentFlagFilter(
        reviewStatuses: [.pending, .escalated]
    )
    static let highRiskOnly = ContentFlagFilter(
        riskLevels: [.highRisk],
        reviewStatuses: [.pending, .escalated]
    )
}
