import Foundation
import Supabase

// MARK: - RemoteModerationKeywordsService

/// Fetches categorized content safety keywords from Supabase and updates
/// the `ContentFilterService` engine config — enabling keyword list changes
/// without redeploying the app.
///
/// ## Database Schema
/// ```sql
/// CREATE TABLE moderation_keywords (
///     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///     keyword  TEXT NOT NULL,
///     category TEXT NOT NULL CHECK (category IN ('self_harm','drugs','alcohol','violence','emergency')),
///     risk     TEXT NOT NULL CHECK (risk     IN ('high_risk','medium_risk','low_risk')),
///     is_active BOOLEAN DEFAULT true,
///     created_at TIMESTAMPTZ DEFAULT now()
/// );
/// ```
///
/// ## Cache Strategy
/// Keywords are fetched on app launch and again when:
/// - App returns to foreground after > 4 hours
/// - Admin pushes a remote config update (future: push-triggered refresh)
///
/// Falls back to `ContentSafetyKeywords` hardcoded values on any failure.
final class RemoteModerationKeywordsService: @unchecked Sendable {

    static let shared = RemoteModerationKeywordsService()

    // MARK: - State

    private(set) var hasRefreshed = false
    private(set) var lastRefreshDate: Date?

    /// Cache TTL — refresh if last fetch was > this many hours ago
    private let cacheTTLHours: Double = 4

    private init() {}

    // MARK: - Refresh

    /// Fetch remote keywords. On success, updates `ContentFilterService`'s engine.
    /// On failure, the existing engine config (hardcoded or previously cached) is kept.
    func refreshIfNeeded() async {
        if let last = lastRefreshDate,
           Date().timeIntervalSince(last) < cacheTTLHours * 3600 {
            return  // still fresh
        }
        await refreshKeywords()
    }

    func refreshKeywords() async {
        guard SupabaseConfig.isConfigured else { return }

        do {
            let rows: [RemoteKeywordRow] = try await SupabaseConfig.client
                .from("moderation_keywords")
                .select("keyword, category, risk")
                .eq("is_active", value: true)
                .execute()
                .value

            let config = buildConfig(from: rows)
            ContentFilterService.shared.updateEngineConfig(config)
            hasRefreshed = true
            lastRefreshDate = Date()

            #if DEBUG
            print("[RemoteModerationKeywords] ✅ Refreshed \(rows.count) keywords from server")
            #endif
        } catch {
            #if DEBUG
            print("[RemoteModerationKeywords] ⚠️ Failed: \(error.localizedDescription) — using hardcoded fallback")
            #endif
            // Do NOT update the engine; it stays on its last-known-good config
        }
    }

    // MARK: - Config Builder

    private func buildConfig(from rows: [RemoteKeywordRow]) -> ContentSafetyEngineConfig {
        func keywords(category: String, risk: String) -> [String] {
            let words = rows.filter { $0.category == category && $0.risk == risk }.map(\.keyword)
            // If server returned nothing for this category+risk, fall back to hardcoded
            return words.isEmpty ? fallback(category: category, risk: risk) : words
        }

        return ContentSafetyEngineConfig(
            selfHarmHigh:   keywords(category: "self_harm",  risk: "high_risk"),
            selfHarmMedium: keywords(category: "self_harm",  risk: "medium_risk"),
            selfHarmLow:    keywords(category: "self_harm",  risk: "low_risk"),
            drugsHigh:      keywords(category: "drugs",      risk: "high_risk"),
            drugsMedium:    keywords(category: "drugs",      risk: "medium_risk"),
            drugsLow:       keywords(category: "drugs",      risk: "low_risk"),
            alcoholHigh:    keywords(category: "alcohol",    risk: "high_risk"),
            alcoholMedium:  keywords(category: "alcohol",    risk: "medium_risk"),
            alcoholLow:     keywords(category: "alcohol",    risk: "low_risk"),
            violenceHigh:   keywords(category: "violence",   risk: "high_risk"),
            violenceMedium: keywords(category: "violence",   risk: "medium_risk"),
            violenceLow:    keywords(category: "violence",   risk: "low_risk"),
            emergency:      rows.filter { $0.category == "emergency" }.map(\.keyword).isEmpty
                                ? ContentSafetyKeywords.emergencySafetyPhrases
                                : rows.filter { $0.category == "emergency" }.map(\.keyword)
        )
    }

    private func fallback(category: String, risk: String) -> [String] {
        switch (category, risk) {
        case ("self_harm", "high_risk"):   return ContentSafetyKeywords.selfHarm.high
        case ("self_harm", "medium_risk"): return ContentSafetyKeywords.selfHarm.medium
        case ("self_harm", "low_risk"):    return ContentSafetyKeywords.selfHarm.low
        case ("drugs",     "high_risk"):   return ContentSafetyKeywords.drugs.high
        case ("drugs",     "medium_risk"): return ContentSafetyKeywords.drugs.medium
        case ("drugs",     "low_risk"):    return ContentSafetyKeywords.drugs.low
        case ("alcohol",   "high_risk"):   return ContentSafetyKeywords.alcohol.high
        case ("alcohol",   "medium_risk"): return ContentSafetyKeywords.alcohol.medium
        case ("alcohol",   "low_risk"):    return ContentSafetyKeywords.alcohol.low
        case ("violence",  "high_risk"):   return ContentSafetyKeywords.violence.high
        case ("violence",  "medium_risk"): return ContentSafetyKeywords.violence.medium
        case ("violence",  "low_risk"):    return ContentSafetyKeywords.violence.low
        default: return []
        }
    }
}

// MARK: - DB Row

private struct RemoteKeywordRow: Decodable, Sendable {
    let keyword: String
    let category: String
    let risk: String
}
