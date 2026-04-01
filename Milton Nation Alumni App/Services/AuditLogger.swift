import Foundation
import Supabase

/// Encodable struct for persisting audit entries to Supabase.
/// Defined at file scope to satisfy Sendable requirements.
nonisolated private struct AuditInsertParams: Encodable, Sendable {
    let action: String
    let userId: UUID?
    let detail: String?
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case action
        case userId = "user_id"
        case detail
        case timestamp
    }
}

enum AuditAction: String {
    // Auth
    case login
    case logout
    case loginFailed
    case loginLockout
    case sessionTimeout
    case sessionRestored
    case mfaVerified
    case mfaFailed

    // Data Access (HIPAA — track all PHI access)
    case viewProfile
    case viewChat
    case viewPosts
    case viewMeetings
    case viewAdminDashboard
    case exportData

    // Data Modification
    case updateProfile
    case resetSobrietyDate
    case createPost
    case sendMessage
    case rsvpMeeting

    // Admin - Content Moderation
    case approvePost
    case rejectPost
    case pinPost
    case unpinPost

    // Admin - User Management
    case promoteUser
    case denyPromotion
    case approveUser
    case rejectUser
    case sendInvite

    // Admin - Meetings
    case createMeeting
    case updateMeeting
    case deleteMeeting

    // Admin - Announcements
    case createAnnouncement
    case updateAnnouncement
    case deleteAnnouncement

    // Admin - Chat Moderation
    case allowFlaggedMessage
    case denyFlaggedMessage

    // Security Events
    case screenshotDetected
    case backgroundProtectionActivated
    case unauthorizedAccessAttempt

    // Content Safety Events
    case contentFlagged        // any risk-level flag detected locally
    case contentEscalated      // high_risk flag sent to server
    case contentFlagReviewed   // admin reviewed a content flag
    case contentFlagDismissed  // admin dismissed a content flag

    // Emergency Access (Break-Glass)
    case emergencyAccessGranted  // super_admin granted timed access to a user's data
    case emergencyAccessRevoked  // super_admin manually revoked an emergency access grant

    // User Rights (HIPAA)
    case exportUserData           // user downloaded their own data
    case accountDeletionRequested // user initiated account deletion
}

struct AuditEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let action: AuditAction
    let userId: UUID?
    let detail: String?
}

final class AuditLogger {
    static let shared = AuditLogger()

    private(set) var entries: [AuditEntry] = []
    private let maxEntries = 500

    /// Buffer for entries that failed to sync to Supabase (offline resilience).
    private var pendingSync: [AuditEntry] = []

    /// Whether to persist audit logs to Supabase (enabled in production).
    var persistToSupabase: Bool = false

    private init() {}

    func log(_ action: AuditAction, userId: UUID? = nil, detail: String? = nil) {
        let entry = AuditEntry(
            timestamp: Date(),
            action: action,
            userId: userId,
            detail: detail
        )
        entries.append(entry)

        // Cap at max entries — remove oldest
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }

        // Persist to Supabase if configured
        if persistToSupabase && SupabaseConfig.isConfigured {
            persistEntry(entry)
        }
    }

    func clear() {
        entries.removeAll()
    }

    // MARK: - Supabase Persistence (HIPAA — 6-year retention)

    /// Attempt to sync any buffered entries that failed during offline periods.
    func syncPendingEntries() {
        guard persistToSupabase, SupabaseConfig.isConfigured else { return }
        let toSync = pendingSync
        pendingSync.removeAll()
        for entry in toSync {
            persistEntry(entry)
        }
    }

    private func persistEntry(_ entry: AuditEntry) {
        let params = AuditInsertParams(
            action: entry.action.rawValue,
            userId: entry.userId,
            detail: entry.detail,
            timestamp: ISO8601DateFormatter().string(from: entry.timestamp)
        )

        Task {
            do {
                try await SupabaseConfig.client.from("audit_logs")
                    .insert(params)
                    .execute()
            } catch {
                // Buffer failed entries for later sync (offline resilience)
                await MainActor.run {
                    self.pendingSync.append(entry)
                }
                #if DEBUG
                print("[AuditLogger] ⚠️ Failed to persist audit log: \(error.localizedDescription)")
                #endif
            }
        }
    }
}
