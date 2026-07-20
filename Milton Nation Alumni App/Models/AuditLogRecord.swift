import Foundation

/// One persisted row of the audit trail, read back for review.
/// Distinct from `AuditEntry` in AuditLogger, which is the in-memory
/// write-side buffer type: who did what, when, and from where.
///
/// HIPAA requires that access and activity be both recorded *and* reviewable.
/// Recording has always worked; this model exists so a compliance reviewer can
/// read the trail in-app instead of needing database access.
struct AuditLogRecord: Identifiable, Codable {
    let id: UUID
    let action: String
    let userId: UUID?
    let detail: String?
    let ipAddress: String?
    let createdAt: Date

    /// Populated from the joined profile when available; the row itself only
    /// stores `user_id`.
    var userName: String?

    enum CodingKeys: String, CodingKey {
        case id, action, detail
        case userId
        case ipAddress
        case createdAt
    }

    /// "promoteUser" -> "Promote User"
    var displayAction: String {
        var out = ""
        for (index, char) in action.enumerated() {
            if char.isUppercase && index > 0 { out.append(" ") }
            out.append(index == 0 ? Character(char.uppercased()) : char)
        }
        return out.replacingOccurrences(of: "_", with: " ")
    }

    /// Actions worth visually flagging in a review — security-relevant or
    /// irreversible. Everything else is routine activity.
    var isSensitive: Bool {
        let flagged = [
            "phoneNumberChanged", "promoteUser", "emergencyAccess", "exportData",
            "accountDeletionRequested", "loginFailed", "loginLockout", "denyPromotion"
        ]
        return flagged.contains(action)
    }

    var formattedTimestamp: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}
