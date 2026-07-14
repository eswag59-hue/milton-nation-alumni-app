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

    /// Upgrade by one level (used by time-immediacy detector).
    /// Caps at `.highRisk` — "tonight + I'm definitely killing myself" doesn't
    /// need to go higher than highRisk; it's already maximum urgency.
    var upgraded: ContentRiskLevel {
        switch self {
        case .safe:       return .lowRisk   // surface awareness of time-bounded distress
        case .lowRisk:    return .mediumRisk
        case .mediumRisk: return .highRisk
        case .highRisk:   return .highRisk
        }
    }
}

/// The harm category associated with a detected phrase.
enum ContentCategory: String, Codable, CaseIterable, Sendable {
    case selfHarm         = "self_harm"
    case drugs            = "drugs"
    case alcohol          = "alcohol"
    case violence         = "violence"
    case eatingDisorder   = "eating_disorder"
    case domesticViolence = "domestic_violence"
    case crisis           = "crisis"
    case userReported     = "user_reported"
    case other            = "other"

    /// Lenient decode: an unrecognized category in a `content_flags` row must
    /// not kill the whole admin queue (one "crisis" row blanked the entire
    /// Content Flags screen). Unknown values map to `.other`.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ContentCategory(rawValue: raw)
            ?? (raw == "user_report" ? .userReported : .other)
    }

    var displayName: String {
        switch self {
        case .selfHarm:         return "Self-Harm / Suicide"
        case .drugs:            return "Substance Use"
        case .alcohol:          return "Alcohol"
        case .violence:         return "Violence / Threat"
        case .eatingDisorder:   return "Eating Disorder"
        case .domesticViolence: return "Domestic Violence"
        case .crisis:           return "Crisis"
        case .userReported:     return "Member Report"
        case .other:            return "Other"
        }
    }

    var icon: String {
        switch self {
        case .selfHarm:         return "heart.slash.fill"
        case .drugs:            return "cross.case.fill"
        case .alcohol:          return "wineglass.fill"
        case .violence:         return "exclamationmark.shield.fill"
        case .eatingDisorder:   return "fork.knife.circle.fill"
        case .domesticViolence: return "house.lodge.fill"
        case .crisis:           return "exclamationmark.triangle.fill"
        case .userReported:     return "flag.fill"
        case .other:            return "questionmark.circle.fill"
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
    /// A user-initiated report of someone else's post or comment (Apple
    /// Guideline 1.2). Lands in the same admin Content Flags queue.
    case userReport      = "user_report"
    case unknown         = "unknown"

    var displayName: String {
        switch self {
        case .chat:          return "Care Team Chat"
        case .communityPost: return "Community Post"
        case .comment:       return "Comment"
        case .profile:       return "Profile"
        case .announcement:  return "Announcement"
        case .userReport:    return "User Report"
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
    //
    // CLINICAL REVIEW REQUIRED before launch. This list draws from:
    // - The Columbia Suicide Severity Rating Scale (C-SSRS)
    // - SAMHSA crisis indicators
    // - Common abbreviations/slang in young-adult digital communication
    // Milton clinical team should add Milton-specific patterns + remove
    // any items that don't apply to your alumni population.

    static let selfHarm = Tier(
        high: [
            // ── Direct suicidal ideation ──
            "kill myself", "killing myself", "kill my self",
            "kms",                           // abbreviation: kill myself
            "kys",                           // kill yourself (directed)
            "end my life", "ending my life",
            "take my own life", "taking my life",
            "commit suicide", "committing suicide",
            "suicide attempt", "attempted suicide",
            "want to die", "wanna die", "wanting to die",
            "wish i was dead", "wish i were dead",
            "wish i could die",
            "better off dead", "better off not existing",
            "don't want to live", "dont want to live",
            "no reason to live", "nothing to live for",
            "not worth living", "life isn't worth it", "life isnt worth it",
            // ── Imminent signals: "I'm done" / "had enough" / disappear ──
            "i'm done", "im done", "i am done",
            "had enough", "i've had enough", "ive had enough",
            "can't do this anymore", "cant do this anymore",
            "i want to disappear", "wish i could disappear",
            "want to disappear forever",
            "leaving this world", "leaving everyone",
            "won't be around", "wont be around",
            "won't be here much longer", "wont be here much longer",
            "world without me",
            "want to sleep forever", "never wake up",
            "make it stop", "i want it to end",
            "ending my pain", "end my pain", "stop the pain",
            "ending things", "ending it tonight",
            // ── Means / method ──
            "going to overdose on purpose", "planning to overdose",
            "od on purpose", "intentional overdose",
            "take all my pills", "swallow all my pills",
            "pills and alcohol",                   // combined method
            "jump off", "jumping off", "step in front of",
            "in front of a train", "in front of a truck",
            "hang myself", "hang my self",
            "tie a noose", "make a noose",
            "shoot myself", "shot myself",
            "loaded gun", "my gun is loaded",
            "cut my wrists", "slit my wrists",
            "drink bleach", "swallow bleach",
            "carbon monoxide", "gas myself",
            "going to end it", "gonna end it",
            "want to end it all", "end it all",
            "plan to end it all", "decided to end it",
            // ── Imminent signals (final words / preparations) ──
            "said my goodbyes", "saying goodbye",
            "wrote a note", "left a note", "writing a note",
            "this is my last", "won't be here tomorrow",
            "my last message", "my last post", "last post ever",
            "goodbye everyone", "final post", "fp",       // "fp" = final post (slang)
            "tell my family i love them",
            "give my stuff away", "giving my things away",
            // ── Self-harm: tools / methods (NEW) ──
            "buying a knife to use on myself",
            "razor on my skin",
            // ── Clinical risk markers (NEW) ──
            "stopped taking my meds", "off my meds",
            "haven't slept in days", "havent slept in days",
            "haven't eaten in days", "havent eaten in days",
        ],
        medium: [
            "thinking about killing myself",
            "thought about ending it",
            "considered suicide", "considering suicide",
            "can't go on anymore", "cannot go on anymore",
            "can't keep going", "cannot keep going",
            "don't want to be here anymore", "dont want to be here",
            "don't want to be here", "dont want to be here",
            "tired of being alive", "tired of living",
            "tired of being here", "tired of being a burden",
            "no way out", "no escape",
            "everyone would be better without me",
            "world is better without me",
            "nobody would miss me", "no one would miss me",
            "what's the point of living", "whats the point of living",
            "what's the point anymore",
            "see no future", "no future for me",
            "thinking about self harm", "thinking about hurting myself",
            "thinking about cutting",
            "hurting myself", "hurt myself",
            "cutting", "cutting myself", "started cutting",
            "cut myself", "cutting again",
            "self harm", "self-harm", "selfharm",
            "sh",                                  // abbreviation for self-harm (single token)
            "burning myself", "burn myself",
            "use a razor",                         // "razor on my skin" is HIGH risk, not medium
        ],
        low: [
            // Distress signals that warrant awareness but not immediate escalation
            "feeling hopeless", "completely hopeless",
            "hate myself", "hating myself",
            "worthless", "i am worthless",
            "burden to everyone", "i'm a burden", "im a burden",
            "feel like a burden",
            "no one cares", "nobody cares about me",
            "no one would notice",
            "all alone", "completely alone", "so alone",
            "can't take it anymore", "cant take it anymore",
            "don't care anymore", "stopped caring",
            "depressed", "deeply depressed", "severely depressed",
            "empty inside", "feel empty",
            "feel nothing", "numb",
            "giving up", "i give up", "ready to give up",
            "suicidal thoughts",             // mentioned but less direct
            "intrusive thoughts about dying",
            "dark thoughts", "really dark place",
            "dissociating", "feel dissociated",
            "having flashbacks", "flashbacks",
            "can't feel my body", "out of my body",
        ]
    )

    // MARK: - Drugs / Substance Use

    static let drugs = Tier(
        high: [
            // ── Opioids ──
            "heroin", "dope", "smack", "junk", "china white",
            "fentanyl", "fent", "fetty",
            "boy",                                 // heroin slang ("got some boy")
            "tar", "black tar",
            "shooting up", "shoot up", "shot up",
            "mainlining", "mainline",
            "using a needle", "needle drugs",
            "track marks", "needle marks",
            "nodding", "nodding out",              // heroin behavioral
            "chasing the dragon",
            "speedball",                           // heroin + cocaine combo
            // ── Active relapse ──
            "using again", "back on drugs",
            "started using again", "picked up again",
            "scored", "copped", "plugged",
            "got my fix", "getting my fix",
            "going to use", "gonna use", "about to use",
            "broke my streak", "broke my sober streak",
            "lost my clean time",
            "went back out",                       // recovery slang for relapse
            // ── Overdose ──
            "overdosed", "od'd", "oded", "od'ed",
            "took too much", "too many pills",
            "almost overdosed", "nearly od'd",
            "narcan", "got narcan'd",              // someone was revived
            // ── Hard stimulants ──
            "shooting meth", "smoking meth", "crystal meth",
            "tweaking", "tweakin",                 // meth use
            "ice",                                 // meth slang
            "crack cocaine", "smoking crack",
            "freebasing",
            // ── Combination / dangerous patterns ──
            "lean", "purple drank", "sizzurp",     // codeine syrup combo
            "robotripping",                        // DXM abuse
            "candy flipping",                      // LSD + MDMA combo
        ],
        medium: [
            // ── Cravings / thinking about use ──
            "craving", "cravings",
            "thinking about using", "want to use",
            "want to get high", "wanna get high",
            "feel like using",
            "miss getting high", "miss being high",
            "looking for stuff", "trying to score",
            "want to score",
            "triggered to use", "triggered today",
            // ── Relapse language ──
            "relapsed", "relapsing", "had a relapse",
            "fell off", "fell off the wagon",
            "slipped", "had a slip",
            "went back to using",
            "tempted to use",
            // ── Named substances ──
            "meth", "methamphetamine", "crystal",
            "cocaine", "coke", "blow", "snow",
            "bumps", "rails", "8-ball", "eight ball",
            "crack",
            "percocet", "percs", "oxycontin", "oxy",
            "hydrocodone", "vicodin", "vikes", "norco",
            "xanax", "bars", "benzos", "klonopin",
            "adderall misuse", "abusing adderall",
            "ecstasy", "molly", "mdma", "rolling",
            "ketamine", "k-hole", "ket",
            "dmt", "ayahuasca",
            "buying drugs", "dealer", "drug deal",
            "spice", "k2",                         // synthetic cannabinoids
            "kratom",                              // emerging concern
        ],
        low: [
            // Mentions without clear intent
            "weed", "marijuana", "cannabis", "pot", "bud",
            "high", "stoned", "blazed",
            "dabs", "dabbing", "wax",              // concentrates
            "pills",
            "prescription", "prescription drugs",
            "plug",                            // slang for drug dealer
            "withdrawal", "withdrawals",
            "detox",
            "clean time at risk",
            "trigger", "triggered",                // generic — flags for awareness
            "haven't been sober", "havent been sober",
        ]
    )

    // MARK: - Alcohol

    static let alcohol = Tier(
        high: [
            // ── Active drinking (relapse) ──
            "drinking again", "started drinking again",
            "had a drink", "had drinks", "got drunk",
            "drunk", "wasted", "hammered", "trashed",
            "blacked out", "black out", "blackout",
            "relapsed on alcohol", "drank alcohol",
            "drank too much", "couldn't stop drinking",
            "back on the bottle", "back on the sauce",
            "broke my sobriety", "broke sobriety",
            "broke my clean time",
            "not sober anymore", "no longer sober",
            // "fell off the wagon" lives in drugs.medium (covers all substances incl. alcohol)
            "dui", "dwi",                         // legal consequences = signal
            "drunk driving",
        ],
        medium: [
            // ── Craving / thinking about drinking ──
            "craving alcohol", "craving a drink",
            "want a drink", "want to drink",
            "wanted a drink",
            "thinking about drinking",
            "miss drinking", "miss alcohol",
            "almost drank", "nearly drank",
            "tempted to drink",
            "buzzed", "have a buzz", "feeling buzzed",
            "drinking problem",                   // self-confession
            // ── Pre-drinking patterns ──
            "pre-game", "pregaming", "pre gaming",
            "happy hour",
            "going to the bar",
        ],
        low: [
            // Mentions without clear intent/relapse
            "wine", "beer", "liquor", "spirits",
            "whiskey", "vodka", "tequila", "rum",
            "gin", "bourbon", "scotch", "champagne",
            "bar", "bars",
            "shots",                              // multiple
            "going out for drinks",
            "hungover", "hangover",
        ]
    )

    // MARK: - Violence / Threats

    static let violence = Tier(
        high: [
            // Direct threats to others
            "going to kill", "gonna kill",
            "want to kill", "i'll kill", "ill kill",
            "going to hurt", "gonna hurt",
            "going to attack", "gonna attack",
            "going to stab", "gonna stab",
            "going to shoot", "gonna shoot",
            "shoot up the place", "shoot up the school",
            "shoot up the office", "shoot up work",
            "have a gun", "have a knife", "armed",
            "make them pay", "they will pay",
            "threaten to hurt",
        ],
        medium: [
            "want to hurt someone", "feel like hurting someone",
            "angry enough to hurt",
            "rage", "in a rage", "blackout rage",
            "violent thoughts", "thoughts of violence",
            "can't control my anger", "cant control my anger",
            "going to lose it",
            "about to snap", "going to snap", "gonna snap",
            "seeing red", "see red",
            "going to do something stupid",
            "threatening", "made threats",
        ],
        low: [
            "angry", "furious", "enraged",
            "hate them", "i hate",
            "want to scream",
        ]
    )

    // MARK: - Eating Disorder (NEW v1)
    //
    // Heavily co-occurring with substance use disorder. Patterns to watch for:
    // restriction (anorexia-leaning), binge/purge (bulimia-leaning), and
    // explicit body-image distress. These signal a need for clinical follow-up
    // and may indicate active eating-disorder relapse alongside SUD recovery.

    static let eatingDisorder = Tier(
        high: [
            // ── Active purging behaviors ──
            "made myself throw up", "make myself throw up",
            "making myself vomit", "made myself vomit",
            "purging", "purged", "purge after eating",
            "throwing up after meals",
            "taking laxatives to lose weight",
            "abusing laxatives",
            "using ipecac",
            // ── Active restriction with danger signals ──
            "haven't eaten in days", "havent eaten in days",
            "not eating", "stopped eating",
            "fasting for days",
            "lost too much weight",
            "passed out from not eating",
            "feel like passing out from hunger",
        ],
        medium: [
            // ── Restrictive / disordered patterns ──
            "restricting", "restricting again",
            "back to restricting",
            "skipping meals", "skipping breakfast",
            "fasting again", "intermittent fasting too much",
            "counting calories obsessively",
            "obsessed with calories",
            "won't eat", "wont eat",
            "throw up my food", "throwing up my food",
            "binge eating", "binged",
            "ate too much", "binge then purge",
            "binging and purging", "bingeing and purging",
            "starving myself",
        ],
        low: [
            // Body-image / weight-related distress
            "feel fat", "feeling fat",
            "hate my body", "disgusted with my body",
            "need to lose weight",
            "weighing myself constantly",
            "anorexia", "bulimia",
            "ana", "mia",                          // pro-ED community shorthand (watch carefully)
            "thinspo",                             // pro-eating-disorder content
            "body checking",
        ]
    )

    // MARK: - Domestic Violence (NEW v1)
    //
    // For incoming threats (user reporting violence done TO them by partner /
    // family / household). Distinct from `violence` category which catches
    // outgoing threats. Triggers care-team outreach + safe-call escalation.

    static let domesticViolence = Tier(
        high: [
            // ── Active physical violence reported ──
            "he hit me", "she hit me", "they hit me",
            "he beat me", "she beat me", "got beat up",
            "he punched me", "she punched me",
            "he choked me", "she choked me",
            "he strangled me", "strangled me",
            "he broke", "broke my arm", "broke my nose",
            "he threw me", "threw me against",
            "he kicked me", "she kicked me",
            // ── Direct threats from intimate partner / household ──
            "going to kill me", "said he'll kill me", "said she'll kill me",
            "threatened to kill me",
            "threatened me with a gun", "pulled a gun on me",
            "threatened me with a knife", "held a knife to",
            "going to hurt me", "said he'll hurt me",
            // ── Imminent danger ──
            "not safe at home", "not safe in my house",
            "afraid for my life", "scared for my life",
            "trapped here", "can't leave him", "cant leave him",
            "can't leave her", "cant leave her",
            "he locked me in", "she locked me in",
        ],
        medium: [
            // ── Ongoing abuse patterns ──
            "abusive partner",
            "abusive husband", "abusive wife",
            "abusive boyfriend", "abusive girlfriend",
            "he hurts me", "she hurts me",
            "afraid of him", "afraid of her", "scared of him", "scared of her",
            "he yells at me every day", "she yells at me every day",
            "controlling everything i do",
            "won't let me leave", "wont let me leave",
            "won't let me see", "wont let me see",
            "takes my phone away",
            "won't let me have money", "wont let me have money",
            "stalking me", "he stalks me", "she stalks me",
            "following me everywhere",
            // ── Recent violence (mild) ──
            "he pushed me", "she pushed me",
            "he shoved me", "she shoved me",
            "grabbed me hard",
        ],
        low: [
            // ── Concerning relationship dynamics ──
            "afraid to go home",
            "walking on eggshells",
            "verbally abusive",
            "name-calling", "calls me names",
            "controlling",
            "he won't talk to me", "she won't talk to me",
            "isolating me from friends", "isolating me from family",
        ]
    )

    // MARK: - Time-Immediacy Markers
    //
    // When any of these markers appears within 10 tokens of a medium/high-risk
    // match, the engine elevates that match's risk by one tier (capped at
    // highRisk). This is what makes "I'm cutting tonight" more urgent than
    // "I've thought about cutting before."
    //
    // Designed to be aggressive on the side of safety. False elevation costs
    // a follow-up admin review; false non-elevation could miss a real
    // emergency.

    static let timeImmediacyMarkers: [String] = [
        "tonight", "today", "right now", "right this moment",
        "in an hour", "in a few hours", "in 30 minutes", "in 15 minutes",
        "this morning", "this afternoon", "this evening",
        "after work", "after school", "when i get home",
        "this weekend", "tomorrow morning",
        "as soon as", "any minute now",
        "minutes away", "hours away",
        "i'm doing it", "im doing it", "doing it now",
        "about to",                                   // "about to use" / "about to do it"
    ]

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
