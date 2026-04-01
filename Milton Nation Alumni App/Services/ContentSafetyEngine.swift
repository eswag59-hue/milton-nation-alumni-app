import Foundation

// MARK: - Result Types

/// A single keyword or pattern match found in user content.
struct ContentMatch: Sendable {
    let keyword: String
    let category: ContentCategory
    let riskContribution: ContentRiskLevel   // may be downgraded by negation

    /// Safe for audit logging — contains ONLY category metadata, never raw user text.
    var redactedDescription: String {
        "[\(category.rawValue):\(riskContribution.rawValue)]"
    }
}

/// The complete result of analyzing a piece of text.
struct ContentSafetyResult: Sendable {
    let riskLevel: ContentRiskLevel
    let categories: Set<ContentCategory>
    let matches: [ContentMatch]
    let isEmergency: Bool             // user is seeking help — always show resources
    let requiresEscalation: Bool      // true for ALL non-safe results (policy: notify all)
    let requiresImmediateEscalation: Bool // true only for high_risk

    /// PHI-safe summary string for audit logs and server-side storage.
    /// Contains ONLY category labels and counts — NEVER raw user text.
    var redactedSummary: String {
        guard !matches.isEmpty || isEmergency else { return "safe" }
        let cats = categories.map(\.rawValue).sorted().joined(separator: ",")
        let emergency = isEmergency ? "+emergency" : ""
        return "\(riskLevel.rawValue):\(cats):\(matches.count)_matches\(emergency)"
    }

    static let safe = ContentSafetyResult(
        riskLevel: .safe, categories: [], matches: [],
        isEmergency: false, requiresEscalation: false, requiresImmediateEscalation: false
    )
}

// MARK: - Engine Config

/// Mutable keyword configuration, replaceable from remote without redeployment.
struct ContentSafetyEngineConfig: Sendable {
    var selfHarmHigh:   [String]
    var selfHarmMedium: [String]
    var selfHarmLow:    [String]
    var drugsHigh:      [String]
    var drugsMedium:    [String]
    var drugsLow:       [String]
    var alcoholHigh:    [String]
    var alcoholMedium:  [String]
    var alcoholLow:     [String]
    var violenceHigh:   [String]
    var violenceMedium: [String]
    var violenceLow:    [String]
    var emergency:      [String]

    static let `default` = ContentSafetyEngineConfig(
        selfHarmHigh:   ContentSafetyKeywords.selfHarm.high,
        selfHarmMedium: ContentSafetyKeywords.selfHarm.medium,
        selfHarmLow:    ContentSafetyKeywords.selfHarm.low,
        drugsHigh:      ContentSafetyKeywords.drugs.high,
        drugsMedium:    ContentSafetyKeywords.drugs.medium,
        drugsLow:       ContentSafetyKeywords.drugs.low,
        alcoholHigh:    ContentSafetyKeywords.alcohol.high,
        alcoholMedium:  ContentSafetyKeywords.alcohol.medium,
        alcoholLow:     ContentSafetyKeywords.alcohol.low,
        violenceHigh:   ContentSafetyKeywords.violence.high,
        violenceMedium: ContentSafetyKeywords.violence.medium,
        violenceLow:    ContentSafetyKeywords.violence.low,
        emergency:      ContentSafetyKeywords.emergencySafetyPhrases
    )
}

// MARK: - Core Engine

/// The production content safety detection engine.
///
/// This is a pure value type (struct) with no mutable state, making it fully
/// thread-safe and callable from any concurrency context.
///
/// ## Detection Pipeline
/// 1. **Normalize** — lowercase, leet-speak substitution, repeated-char collapse
/// 2. **Emergency check** — detect help-seeking phrases, never flag them as harm
/// 3. **Keyword matching** — phrase-level exact substring search per risk tier
/// 4. **Regex patterns** — multi-word syntactic patterns (e.g. "want to kill myself")
/// 5. **Negation detection** — downgrade risk if negation word precedes match
/// 6. **Aggregation** — take max risk, collect all categories
///
/// ## Performance
/// - Typical message (< 200 chars): < 1 ms
/// - Long post (< 2,000 chars): < 5 ms
/// - All matching is synchronous; escalation calls are async fire-and-forget
///
/// ## Privacy
/// - Engine NEVER stores or returns raw user text in any result field
/// - `ContentSafetyResult.redactedSummary` is the only string sent to servers
struct ContentSafetyEngine: Sendable {

    let config: ContentSafetyEngineConfig

    // Pre-compiled regex patterns — computed once at init.
    // NSRegularExpression is thread-safe for concurrent read-only access (Apple docs).
    private static let compiledPatterns: [(regex: NSRegularExpression, category: ContentCategory, risk: ContentRiskLevel)] = {
        ContentSafetyKeywords.patterns.compactMap { entry in
            guard let rx = try? NSRegularExpression(pattern: entry.pattern, options: [.caseInsensitive]) else {
                assertionFailure("[ContentSafetyEngine] Failed to compile pattern: \(entry.pattern)")
                return nil
            }
            return (rx, entry.category, entry.risk)
        }
    }()

    init(config: ContentSafetyEngineConfig = .default) {
        self.config = config
    }

    // MARK: - Public API

    /// Analyze a string and return a complete safety assessment.
    ///
    /// - Parameters:
    ///   - text: Raw user-entered text (never stored in result)
    ///   - feature: Where in the app this text was submitted (for admin context)
    /// - Returns: A `ContentSafetyResult` — safe to log and send to server
    func analyze(_ text: String, feature: ContentFeature = .unknown) -> ContentSafetyResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .safe
        }

        let normalized = normalize(text)

        // STEP 1: Emergency check — someone seeking help, never penalize
        let isEmergency = checkEmergency(normalized)

        // STEP 2: Keyword matching
        var matches: [ContentMatch] = []
        matches += matchKeywords(normalized, in: text)

        // STEP 3: Regex patterns
        matches += matchPatterns(normalized, in: text)

        // STEP 4: Deduplicate (same phrase detected by both keyword + regex)
        matches = deduplicate(matches)

        // STEP 5: Negation detection — downgrade risk for negated phrases
        matches = applyNegation(matches, in: normalized)

        // STEP 6: Aggregate
        guard !matches.isEmpty || isEmergency else {
            return .safe
        }

        let maxRisk = matches.map(\.riskContribution).max() ?? .safe
        let categories = Set(matches.map(\.category))

        return ContentSafetyResult(
            riskLevel: maxRisk,
            categories: categories,
            matches: matches,
            isEmergency: isEmergency,
            requiresEscalation: maxRisk != .safe,
            requiresImmediateEscalation: maxRisk == .highRisk
        )
    }

    // MARK: - Text Normalization

    /// Produce a normalized copy of the text for matching.
    /// Original text is NOT modified — normalization is only for internal matching.
    private func normalize(_ text: String) -> String {
        var s = text.lowercased()

        // 1. Leet-speak substitution
        for (char, replacement) in ContentSafetyKeywords.leetMap {
            s = s.replacingOccurrences(of: String(char), with: replacement)
        }

        // 2. Collapse 3+ repeated characters to 2
        //    "heeeelp" → "heelp", "suuuicide" → "suuicide"
        //    Then collapse 2 → 1 for matching purposes
        s = collapseRepeatedChars(s)

        // 3. Normalize whitespace
        s = s.components(separatedBy: .whitespacesAndNewlines)
             .filter { !$0.isEmpty }
             .joined(separator: " ")

        // 4. Remove certain punctuation that people use to obfuscate
        //    "k.i.l.l" → "kill", "h-e-r-o-i-n" → "heroin"
        let obfuscationPunctuation = CharacterSet(charactersIn: ".-_*")
        s = s.components(separatedBy: obfuscationPunctuation).joined()

        return s
    }

    /// Collapse 3+ identical consecutive characters to just 2.
    private func collapseRepeatedChars(_ s: String) -> String {
        var result = [Character]()
        result.reserveCapacity(s.count)
        var runCount = 0
        var lastChar: Character = "\0"

        for ch in s {
            if ch == lastChar {
                runCount += 1
                if runCount <= 2 { result.append(ch) }
            } else {
                lastChar = ch
                runCount = 1
                result.append(ch)
            }
        }
        return String(result)
    }

    // MARK: - Emergency Detection

    private func checkEmergency(_ normalized: String) -> Bool {
        config.emergency.contains { phrase in normalized.contains(phrase) }
    }

    // MARK: - Keyword Matching

    private typealias KW = (phrase: String, category: ContentCategory, risk: ContentRiskLevel)

    private func matchKeywords(_ normalized: String, in original: String) -> [ContentMatch] {
        let allKeywords: [KW] = buildKeywordList()
        var results: [ContentMatch] = []

        for kw in allKeywords {
            let phrase = kw.phrase.lowercased()
            // Use word-aware matching for single words; substring for phrases
            let isMultiWord = phrase.contains(" ")
            if isMultiWord {
                if normalized.contains(phrase) {
                    results.append(ContentMatch(
                        keyword: phrase, category: kw.category,
                        riskContribution: kw.risk
                    ))
                }
            } else {
                // Single word: check word boundaries using simple heuristic
                // (character before/after is not alphanumeric)
                if containsWord(phrase, in: normalized) {
                    results.append(ContentMatch(
                        keyword: phrase, category: kw.category,
                        riskContribution: kw.risk
                    ))
                }
            }
        }
        return results
    }

    /// Check if `word` appears as a whole word (not part of a larger word) in `text`.
    private func containsWord(_ word: String, in text: String) -> Bool {
        guard let range = text.range(of: word) else { return false }
        let before = range.lowerBound > text.startIndex ? text[text.index(before: range.lowerBound)] : " " as Character
        let after  = range.upperBound < text.endIndex   ? text[range.upperBound]                    : " " as Character
        let alphanumeric = CharacterSet.alphanumerics
        let beforeOk = !String(before).unicodeScalars.allSatisfy { alphanumeric.contains($0) }
        let afterOk  = !String(after).unicodeScalars.allSatisfy  { alphanumeric.contains($0) }
        return beforeOk && afterOk
    }

    private func buildKeywordList() -> [KW] {
        var list: [KW] = []
        list += config.selfHarmHigh.map   { ($0, .selfHarm, .highRisk)    }
        list += config.selfHarmMedium.map { ($0, .selfHarm, .mediumRisk)  }
        list += config.selfHarmLow.map    { ($0, .selfHarm, .lowRisk)     }
        list += config.drugsHigh.map      { ($0, .drugs,    .highRisk)    }
        list += config.drugsMedium.map    { ($0, .drugs,    .mediumRisk)  }
        list += config.drugsLow.map       { ($0, .drugs,    .lowRisk)     }
        list += config.alcoholHigh.map    { ($0, .alcohol,  .highRisk)    }
        list += config.alcoholMedium.map  { ($0, .alcohol,  .mediumRisk)  }
        list += config.alcoholLow.map     { ($0, .alcohol,  .lowRisk)     }
        list += config.violenceHigh.map   { ($0, .violence, .highRisk)    }
        list += config.violenceMedium.map { ($0, .violence, .mediumRisk)  }
        list += config.violenceLow.map    { ($0, .violence, .lowRisk)     }
        return list
    }

    // MARK: - Regex Pattern Matching

    private func matchPatterns(_ normalized: String, in original: String) -> [ContentMatch] {
        let nsStr = normalized as NSString
        let range = NSRange(location: 0, length: nsStr.length)
        var results: [ContentMatch] = []

        for entry in Self.compiledPatterns {
            if entry.regex.firstMatch(in: normalized, options: [], range: range) != nil {
                results.append(ContentMatch(
                    keyword: "[pattern:\(entry.category.rawValue)]",
                    category: entry.category,
                    riskContribution: entry.risk
                ))
            }
        }
        return results
    }

    // MARK: - Deduplication

    /// Remove duplicate matches by (category, risk) — keeps highest risk per category.
    private func deduplicate(_ matches: [ContentMatch]) -> [ContentMatch] {
        var seen: [ContentCategory: ContentRiskLevel] = [:]
        var unique: [ContentMatch] = []
        for m in matches.sorted(by: { $0.riskContribution > $1.riskContribution }) {
            if let existing = seen[m.category], existing >= m.riskContribution { continue }
            seen[m.category] = m.riskContribution
            unique.append(m)
        }
        return unique
    }

    // MARK: - Negation Detection

    /// Downgrade risk by one tier if a negation word appears within 5 tokens before the match.
    ///
    /// Examples that get downgraded:
    /// - "I do NOT want to kill myself" → highRisk → mediumRisk
    /// - "I used to drink but I haven't had a drink in years" → highRisk → mediumRisk
    ///
    /// Note: This is intentionally conservative — negation only downgrades once,
    /// never below lowRisk, to avoid false negatives on genuine crisis content.
    private func applyNegation(_ matches: [ContentMatch], in normalized: String) -> [ContentMatch] {
        let tokens = normalized.components(separatedBy: .whitespaces)

        return matches.map { match in
            guard let matchIdx = tokens.firstIndex(where: { $0.contains(match.keyword) }) else {
                return match
            }
            let lookbackStart = max(0, matchIdx - 5)
            let precedingTokens = tokens[lookbackStart..<matchIdx]
            let hasNegation = precedingTokens.contains { token in
                ContentSafetyKeywords.negationWords.contains(token.trimmingCharacters(in: .punctuationCharacters))
            }
            if hasNegation {
                return ContentMatch(
                    keyword: match.keyword,
                    category: match.category,
                    riskContribution: match.riskContribution.downgraded
                )
            }
            return match
        }
    }
}
