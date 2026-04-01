import Foundation

// MARK: - Risk Level & Category Enums

/// Granular risk classification for flagged content.
enum ContentRiskLevel: String, Codable, CaseIterable, Comparable, Sendable {
    case safe       = "safe"
    case lowRisk    = "low_risk"
    case mediumRisk = "medium_risk"
    case highRisk   = "high_risk"

    private static let order: [ContentRiskLevel] = [.safe, .lowRisk, .mediumRisk, .highRisk]

    static func < (lhs: ContentRiskLevel, rhs: ContentRiskLevel) -> Bool {
        (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }

    var displayName: String {
        switch self {
        case .safe:       return "Safe"
        case .lowRisk:    return "Low Risk"
        case .mediumRisk: return "Medium Risk"
        case .highRisk:   return "High Risk"
        }
    }

    /// Every non-safe level escalates to admins per platform policy.
    var requiresEscalation: Bool { self != .safe }

    /// High risk triggers push notification with elevated priority.
    var isImmediatelyDangerous: Bool { self == .highRisk }

    /// Downgrade by one level (used by negation detector).
    var downgraded: ContentRiskLevel {
        switch self {
        case .safe:       return .safe
        case .lowRisk:    return .safe
        case .mediumRisk: return .lowRisk
        case .highRisk:   return .mediumRisk
        }
    }
}

/// The harm category associated with a detected phrase.
enum ContentCategory: String, Codable, CaseIterable, Sendable {
    case selfHarm = "self_harm"
    case drugs    = "drugs"
    case alcohol  = "alcohol"
    case violence = "violence"

    var displayName: String {
        switch self {
        case .selfHarm: return "Self-Harm / Suicide"
        case .drugs:    return "Substance Use"
        case .alcohol:  return "Alcohol"
        case .violence: return "Violence / Threat"
        }
    }

    var icon: String {
        switch self {
        case .selfHarm: return "heart.slash.fill"
        case .drugs:    return "cross.case.fill"
        case .alcohol:  return "wineglass.fill"
        case .violence: return "exclamationmark.shield.fill"
        }
    }
}

/// The in-app feature or screen where the content was submitted.
enum ContentFeature: String, Codable, Sendable {
    case chat            = "chat"
    case communityPost   = "community_post"
    case comment         = "comment"
    case profile         = "profile"
    case announcement    = "announcement"
    case unknown         = "unknown"

    var displayName: String {
        switch self {
        case .chat:          return "Care Team Chat"
        case .communityPost: return "Community Post"
        case .comment:       return "Comment"
        case .profile:       return "Profile"
        case .announcement:  return "Announcement"
        case .unknown:       return "Unknown"
        }
    }
}

// MARK: - Keyword Database

/// The complete, production-grade keyword database for content safety detection.
///
/// Organized by category × risk tier. Updated remotely via `RemoteModerationKeywordsService`.
/// All phrases are lowercase; the engine normalizes input before comparison.
enum ContentSafetyKeywords {

    struct Tier: Sendable {
        let high: [String]
        let medium: [String]
        let low: [String]
    }

    // MARK: - Self-Harm / Suicide

    static let selfHarm = Tier(
        high: [
            // Direct suicidal ideation
            "kill myself", "killing myself", "kill my self",
            "kms",                           // abbreviation: kill myself
            "kys",                           // kill yourself (directed)
            "end my life", "ending my life",
            "take my own life", "taking my life",
            "commit suicide", "committing suicide",
            "suicide attempt", "attempted suicide",
            "want to die", "wanna die", "wanting to die",
            "wish i was dead", "wish i were dead",
            "better off dead", "better off not existing",
            "don't want to live", "dont want to live",
            "no reason to live", "nothing to live for",
            "not worth living", "life isn't worth it",
            // Means / method
            "going to overdose on purpose", "planning to overdose",
            "take all my pills", "swallow all my pills",
            "jump off", "step in front of",
            "hang myself", "hang my self",
            "shoot myself", "shot myself",
            "cut my wrists", "slit my wrists",
            "going to end it", "gonna end it",
            "want to end it all", "end it all",
            "plan to end it all", "decided to end it",
            // Imminent signals
            "said my goodbyes", "wrote a note",
            "this is my last", "won't be here tomorrow",
            "my last message", "goodbye everyone",
        ],
        medium: [
            "thinking about killing myself",
            "thought about ending it",
            "considered suicide",
            "can't go on anymore", "cannot go on anymore",
            "can't keep going", "cannot keep going",
            "don't want to be here anymore", "dont want to be here",
            "tired of being alive", "tired of living",
            "no way out", "no escape",
            "everyone would be better without me",
            "world is better without me",
            "nobody would miss me", "no one would miss me",
            "what's the point of living",
            "see no future", "no future for me",
            "thinking about self harm", "thinking about hurting myself",
            "hurting myself", "hurt myself",
            "cutting", "cutting myself", "started cutting",
            "self harm", "self-harm", "selfharm",
            "burning myself",
        ],
        low: [
            // Distress signals that warrant awareness but not immediate escalation
            "feeling hopeless", "completely hopeless",
            "hate myself", "hating myself",
            "worthless", "i am worthless",
            "burden to everyone", "i'm a burden", "im a burden",
            "no one cares", "nobody cares about me",
            "all alone", "completely alone",
            "can't take it anymore", "cant take it anymore",
            "don't care anymore", "stopped caring",
            "depressed", "deeply depressed",
            "empty inside", "feel empty",
            "giving up", "i give up",
            "suicidal thoughts",             // mentioned but less direct
            "intrusive thoughts about dying",
        ]
    )

    // MARK: - Drugs / Substance Use

    static let drugs = Tier(
        high: [
            // Opioids
            "heroin", "dope", "smack", "junk", "china white",
            "fentanyl", "fent", "fetty",
            "shooting up", "shoot up", "shot up",
            "mainlining", "mainline",
            "using a needle", "needle drugs",
            // Active relapse
            "using again", "back on drugs",
            "started using again", "picked up again",
            "scored", "copped", "plugged",
            "got my fix", "getting my fix",
            "going to use", "gonna use", "about to use",
            // Overdose
            "overdosed", "od'd", "oded",
            "took too much", "too many pills",
            "almost overdosed", "nearly od'd",
            // Hard stimulants
            "shooting meth", "smoking meth", "crystal meth",
            "crack cocaine", "smoking crack",
        ],
        medium: [
            // Cravings / thinking about use
            "craving", "cravings",
            "thinking about using", "want to use",
            "want to get high", "wanna get high",
            "feel like using",
            "miss getting high", "miss being high",
            // Relapse language
            "relapsed", "relapsing", "had a relapse",
            "fell off", "fell off the wagon",
            "slipped", "had a slip",
            "went back to using",
            // Named substances
            "meth", "methamphetamine", "crystal",
            "cocaine", "coke", "blow", "snow",
            "crack",
            "percocet", "percs", "oxycontin", "oxy",
            "hydrocodone", "vicodin", "vikes", "norco",
            "xanax", "bars", "benzos", "klonopin",
            "adderall misuse", "abusing adderall",
            "ecstasy", "molly", "mdma",
            "buying drugs", "dealer",
        ],
        low: [
            // Mentions without clear intent
            "weed", "marijuana", "cannabis", "pot", "bud",
            "high", "stoned", "blazed",
            "pills",
            "prescription", "prescription drugs",
            "plug",                            // slang for drug dealer
            "withdrawal", "withdrawals",
            "detox",
            "clean time at risk",
        ]
    )

    // MARK: - Alcohol

    static let alcohol = Tier(
        high: [
            // Active drinking (relapse)
            "drinking again", "started drinking again",
            "had a drink", "had drinks",
            "drunk", "wasted", "hammered",
            "blacked out", "black out",
            "relapsed on alcohol", "drank alcohol",
            "back on the bottle", "back on the sauce",
            "broke my sobriety",
            "not sober anymore",
        ],
        medium: [
            // Craving / thinking about drinking
            "craving alcohol", "craving a drink",
            "want a drink", "want to drink",
            "thinking about drinking",
            "miss drinking", "miss alcohol",
            "almost drank", "nearly drank",
            "tempted to drink",
        ],
        low: [
            // Mentions without clear intent/relapse
            "wine", "beer", "liquor", "spirits", "whiskey", "vodka",
            "bar", "bars",
            "going out for drinks",
        ]
    )

    // MARK: - Violence / Threats

    static let violence = Tier(
        high: [
            // Direct threats to others
            "going to kill", "gonna kill",
            "want to kill", "i'll kill",
            "going to hurt", "gonna hurt",
            "going to attack", "gonna attack",
            "going to stab", "gonna stab",
            "going to shoot", "gonna shoot",
            "have a gun", "have a knife", "armed",
            "make them pay", "they will pay",
            "threaten to hurt",
        ],
        medium: [
            "want to hurt someone", "feel like hurting someone",
            "angry enough to hurt",
            "rage", "in a rage",
            "violent thoughts", "thoughts of violence",
            "can't control my anger",
            "going to do something stupid",
            "threatening", "made threats",
        ],
        low: [
            "angry", "furious", "enraged",
            "hate them", "i hate",
            "want to scream",
        ]
    )

    // MARK: - Emergency Fail-Safe Phrases
    //
    // These phrases indicate someone is SEEKING help.
    // The engine NEVER flags these as harmful — instead it surfaces
    // `SupportResourcesView` to provide immediate assistance.
    // These take priority over any keyword match.

    static let emergencySafetyPhrases: [String] = [
        "call 988", "988", "suicide hotline",
        "crisis line", "crisis hotline",
        "call 911", "call the police",
        "need help now", "please help me",
        "i need help", "help me please",
        "i'm in crisis", "im in crisis",
        "crisis text line",
        "samhsa", "national helpline",
        "going to call for help",
        "reaching out for help",
        "texting a crisis line",
    ]

    // MARK: - Regex Patterns

    /// Regex patterns for detecting phrases that keyword matching might miss.
    /// All patterns are case-insensitive and applied to normalized text.
    static let patterns: [(pattern: String, category: ContentCategory, risk: ContentRiskLevel)] = [
        // Self-harm: "want/wanna/going to/gonna/plan to + harm verb + self"
        (#"\b(want|wanna|going to|gonna|plan to|planning to|thinking of) (kill|end|hurt|harm) (my\s*self|myself|me)\b"#,   .selfHarm, .highRisk),
        (#"\b(want|wanna|wish) (i was|i were|to be) dead\b"#,                                                              .selfHarm, .highRisk),
        (#"\b(no|not|don'?t) (want|feel like|see a) (living|being here|going on|continuing)\b"#,                          .selfHarm, .mediumRisk),
        (#"\bkm+s\b"#,                                                                                                     .selfHarm, .highRisk),  // kms / kmss
        (#"\b(self[- ]?harm(ing)?|selfharm)\b"#,                                                                          .selfHarm, .mediumRisk),

        // Drugs: OD patterns
        (#"\bOD'?[ds]?\b"#,                                                                                               .drugs, .highRisk),   // OD, OD'd, ODs
        (#"\b(shoot|shot|shooting|shoot up)\b"#,                                                                          .drugs, .highRisk),

        // Drugs: relapse patterns
        (#"\b(back\s+on|using\s+again|started\s+using|picked\s+up\s+again)\b"#,                                          .drugs, .highRisk),
        (#"\b(scored|copped)\s+(some|a|the)?\s*(dope|meth|fent|pills|stuff|drugs|heroin)\b"#,                            .drugs, .highRisk),

        // Alcohol: relapse
        (#"\b(had|having|drank|drinking)\s+(a\s+)?(drink|drinks|beer|wine|shot|alcohol)\b"#,                             .alcohol, .highRisk),
        (#"\b(broke|breaking)\s+(my\s+)?(sobriety|clean\s+time)\b"#,                                                     .alcohol, .highRisk),

        // Violence: direct threat
        (#"\b(going|gonna|want|plan)\s+to\s+(kill|hurt|harm|attack|shoot|stab)\s+\w+"#,                                  .violence, .highRisk),
        (#"\b(i'?ll|i\s+will)\s+(kill|hurt|destroy|end)\s+\w+"#,                                                        .violence, .highRisk),
    ]

    // MARK: - Negation Words

    /// Words that, when appearing within 5 tokens before a match,
    /// downgrade the risk level by one tier.
    static let negationWords: Set<String> = [
        "not", "never", "no", "don't", "doesnt", "didn't",
        "won't", "wouldn't", "can't", "cannot",
        "isn't", "aren't", "wasn't", "weren't",
        "haven't", "hasn't", "hadn't", "shouldn't",
        "no longer", "used to", "past", "before",
    ]

    // MARK: - Leet-Speak Substitution Map

    /// Maps leet-speak characters to their plaintext equivalents.
    /// Applied during text normalization to catch obfuscated keywords.
    static let leetMap: [(Character, String)] = [
        ("0", "o"), ("1", "i"), ("3", "e"), ("4", "a"),
        ("5", "s"), ("6", "b"), ("7", "t"), ("8", "b"),
        ("@", "a"), ("$", "s"), ("|", "i"),
    ]
}
