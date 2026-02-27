import Foundation

/// Legacy keyword namespace — delegates to `ContentSafetyKeywords` for the
/// comprehensive, remotely-updatable keyword database.
/// Kept for backward compatibility. New code should use `ContentSafetyKeywords` directly.
enum ModerationKeywords {

    /// Terms that trigger moderation review (low + medium risk across all categories).
    static var flagged: [String] {
        ContentSafetyKeywords.selfHarm.low   + ContentSafetyKeywords.selfHarm.medium
        + ContentSafetyKeywords.drugs.low    + ContentSafetyKeywords.drugs.medium
        + ContentSafetyKeywords.alcohol.low  + ContentSafetyKeywords.alcohol.medium
        + ContentSafetyKeywords.violence.low + ContentSafetyKeywords.violence.medium
    }

    /// Terms indicating an immediate crisis (high risk across all categories).
    static var crisis: [String] {
        ContentSafetyKeywords.selfHarm.high
        + ContentSafetyKeywords.drugs.high
        + ContentSafetyKeywords.alcohol.high
        + ContentSafetyKeywords.violence.high
    }
}
