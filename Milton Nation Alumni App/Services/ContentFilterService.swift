import Foundation
import Supabase

// MARK: - ContentFilterService

/// Production content moderation service.
///
/// ## Architecture
/// - **Stage 1 (sync)**: `ContentSafetyEngine` runs locally on-device — < 1ms, no network
/// - **Stage 2 (async)**: `flag-content` Edge Function stores flag + notifies ALL admins
///
/// ## Escalation Policy (per platform rules)
/// - **ANY risk level** (low / medium / high) → notify both `admin` and `super_admin`
/// - High risk additionally sets push notification priority to "high"
///
/// ## Privacy / HIPAA
/// - Raw user text is NEVER sent to the server
/// - Only `ContentSafetyResult.redactedSummary` (category labels + counts) is transmitted
/// - Audit log entries contain only redacted metadata
///
/// Usage:
/// ```swift
/// let result = await ContentFilterService.shared.analyzeAndEscalate(
///     text, userId: currentUser.id, feature: .communityPost
/// )
/// if result.isEmergency || result.riskLevel != .safe {
///     showSupportResources = true
/// }
/// ```
final class ContentFilterService: @unchecked Sendable {

    static let shared = ContentFilterService()

    // MARK: - Private State

    /// The detection engine — updated when remote keywords refresh.
    private var engine: ContentSafetyEngine = ContentSafetyEngine()
    private let lock = NSLock()

    private init() {}

    // MARK: - Engine Config Update (called by RemoteModerationKeywordsService)

    /// Replace the engine config with freshly downloaded remote keywords.
    func updateEngineConfig(_ config: ContentSafetyEngineConfig) {
        lock.withLock { engine = ContentSafetyEngine(config: config) }
    }

    // MARK: - Public API

    /// Run text through the full moderation pipeline.
    ///
    /// - Returns: `ContentSafetyResult` — safe to display, log, and act on.
    ///   Never throws; failures in the escalation step are silently buffered.
    func analyzeAndEscalate(
        _ text: String,
        userId: UUID? = nil,
        feature: ContentFeature = .unknown
    ) async -> ContentSafetyResult {

        // Stage 1: local, synchronous, O(n)
        let result = lock.withLock { engine.analyze(text, feature: feature) }

        // Stage 2: async server escalation for ALL non-safe results
        if result.requiresEscalation || result.isEmergency {
            await escalateToServer(result: result, userId: userId, feature: feature)
        }

        // Audit log — redacted, never raw text
        AuditLogger.shared.log(
            result.riskLevel == .highRisk ? .contentEscalated : .contentFlagged,
            userId: userId,
            detail: result.redactedSummary
        )

        return result
    }

    /// Synchronous local-only analysis — use when you cannot await (e.g., onChange).
    /// Does NOT escalate to server; call `escalateToServer` separately if needed.
    func analyzeLocal(_ text: String) -> ContentSafetyResult {
        lock.withLock { engine.analyze(text) }
    }

    // MARK: - Legacy API (backward compat with existing call sites)

    /// Deprecated. Use `analyzeAndEscalate(_:userId:feature:)`.
    @available(*, deprecated, renamed: "analyzeAndEscalate(_:userId:feature:)")
    func moderateText(_ text: String) async -> ModerationResult {
        let result = await analyzeAndEscalate(text)
        switch result.riskLevel {
        case .safe:
            return ModerationResult(status: .clean, matchedKeywords: [])
        case .lowRisk, .mediumRisk:
            return ModerationResult(status: .flagged, matchedKeywords: result.matches.map(\.keyword))
        case .highRisk:
            return ModerationResult(status: .crisis, matchedKeywords: result.matches.map(\.keyword))
        }
    }

    /// Synchronous local pre-filter — kept for backward compat.
    func localFilter(_ text: String) -> ModerationResult {
        let result = analyzeLocal(text)
        switch result.riskLevel {
        case .safe:
            // Emergency help-seeking phrases (e.g. "need help now") surface as crisis
            // so admins are notified even when no harmful keywords are present.
            let status: ModerationResult.Status = result.isEmergency ? .crisis : .clean
            return ModerationResult(status: status, matchedKeywords: [])
        case .lowRisk, .mediumRisk:
            return ModerationResult(status: .flagged, matchedKeywords: result.matches.map(\.keyword))
        case .highRisk:
            return ModerationResult(status: .crisis, matchedKeywords: result.matches.map(\.keyword))
        }
    }

    func postStatus(for result: ModerationResult, approvedPostCount: Int, autoApproveThreshold: Int = 10) -> PostStatus {
        switch result.status {
        case .crisis:  return .flaggedForCrisis
        case .flagged: return .pendingReview
        case .clean:   return approvedPostCount >= autoApproveThreshold ? .approved : .pending
        }
    }

    func messageStatus(for result: ModerationResult) -> MessageModerationStatus {
        switch result.status {
        case .crisis:  return .flaggedForCrisis
        case .flagged: return .flagged
        case .clean:   return .clean
        }
    }

    // MARK: - Server Escalation (Stage 2)

    /// Send a REDACTED flag record to the `flag-content` Edge Function.
    ///
    /// The Edge Function:
    /// 1. Stores the flag in `content_flags` table
    /// 2. Sends push notification to ALL admins + super_admins
    ///
    /// Raw text is NEVER included — only `result.redactedSummary`.
    private func escalateToServer(
        result: ContentSafetyResult,
        userId: UUID?,
        feature: ContentFeature
    ) async {
        guard SupabaseConfig.isConfigured else { return }

        do {
            let session = try? await SupabaseConfig.client.auth.session
            guard let accessToken = session?.accessToken else { return }

            let payload = ContentFlagPayload(
                userId: userId?.uuidString,
                riskLevel: result.riskLevel.rawValue,
                categories: result.categories.map(\.rawValue).sorted(),
                feature: feature.rawValue,
                redactedSummary: result.redactedSummary,
                isEmergency: result.isEmergency,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )

            let data = try JSONEncoder().encode(payload)

            _ = try await SupabaseConfig.client.functions
                .invoke("flag-content", options: .init(
                    headers: ["Authorization": "Bearer \(accessToken)"],
                    body: data
                ))
        } catch {
            // Log locally but don't crash — moderation cannot block the user flow
            CrashReportingService.shared.recordError(error, context: "ContentFilterService.escalateToServer")
            #if DEBUG
            print("[ContentFilterService] ⚠️ Escalation failed: \(error.localizedDescription)")
            #endif
            AuditLogger.shared.log(.contentFlagged, userId: userId,
                                   detail: "escalation_failed:\(result.redactedSummary)")
        }
    }

    // MARK: - User Reports (Apple Guideline 1.2)

    /// File a user-initiated report of objectionable content (a post or a
    /// comment) to the SAME `flag-content` Edge Function the moderation engine
    /// uses. The flag lands in the existing admin Content Flags queue — no new
    /// admin surface is needed.
    ///
    /// - Parameters:
    ///   - kind: `"post"` or `"comment"` — used to build the redacted summary.
    ///   - targetId: the UUID of the reported post/comment.
    ///   - reporterId: the current user's id (optional; used for audit only).
    ///   - reason: an optional short reason supplied by the reporter. NEVER
    ///     contains the reported content itself, so it is safe to transmit.
    /// - Throws: rethrows network/encoding errors so the caller can surface a
    ///   failure toast. (Distinct from `escalateToServer`, which is fire-and-forget.)
    func reportUserContent(
        kind: String,
        targetId: UUID,
        reporterId: UUID?,
        reason: String?
    ) async throws {
        guard SupabaseConfig.isConfigured else { return }

        let session = try? await SupabaseConfig.client.auth.session
        guard let accessToken = session?.accessToken else {
            throw NSError(domain: "ContentFilterService.reportUserContent", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in."])
        }

        // Redacted summary: only the kind + target id (and a coarse reason tag).
        // The reported *content* is never sent — admins look it up by id.
        var summary = "user_report:\(kind):\(targetId.uuidString)"
        if let reason, !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Cap the reason so we never accidentally smuggle long text upstream.
            summary += ":reason=\(reason.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))"
        }

        let payload = ContentFlagPayload(
            userId: reporterId?.uuidString,
            riskLevel: "low_risk",
            categories: ["user_reported"],
            feature: ContentFeature.userReport.rawValue,
            redactedSummary: summary,
            isEmergency: false,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        let data = try JSONEncoder().encode(payload)

        _ = try await SupabaseConfig.client.functions
            .invoke("flag-content", options: .init(
                headers: ["Authorization": "Bearer \(accessToken)"],
                body: data
            ))

        AuditLogger.shared.log(.contentFlagged, userId: reporterId,
                               detail: "user_report:\(kind):\(targetId.uuidString)")
    }
}

// MARK: - Payload (sent to Edge Function — no raw text)

private struct ContentFlagPayload: Encodable {
    let userId: String?
    let riskLevel: String
    let categories: [String]
    let feature: String
    let redactedSummary: String
    let isEmergency: Bool
    let timestamp: String
}

// MARK: - Legacy Types (backward compat — preserved for existing call sites)

/// Retained from the original ContentFilterService for backward compatibility.
/// New code should use `ContentSafetyResult` from `ContentSafetyEngine` directly.
struct ModerationResult {
    enum Status {
        case clean   // No flags
        case flagged // Matched keywords (low / medium risk)
        case crisis  // High-risk content requiring immediate escalation
    }
    let status: Status
    let matchedKeywords: [String]

    var isCrisis: Bool { status == .crisis }
    var isFlagged: Bool { status == .flagged }
}
