import SwiftUI

struct DailyReflectionCard: View {
    let quote: DailyQuote?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundStyle(AppTheme.accent)
                Text("Daily Reflection")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            if let quote {
                VStack(alignment: .leading, spacing: 4) {
                    // Opening quotation mark — typographically correct left double quote
                    Text("\u{201C}")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.accentLight)
                        .lineSpacing(0)
                        .padding(.bottom, -24)
                        .padding(.leading, -2)

                    Text(quote.text)
                        .font(.body)
                        .italic()
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.leading, 4)

                    // Closing quotation mark — right double quote, right-aligned
                    Text("\u{201D}")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.accentLight)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, -24)
                        .padding(.trailing, -2)

                    // Hide the attribution line entirely for anonymous quotes —
                    // "— Unknown" reads as a data bug, not a byline.
                    if let attribution = Self.displayAttribution(for: quote) {
                        Text("— \(attribution)")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.accent)
                            .padding(.top, -8)
                    }
                }
            } else {
                Text("Loading today's reflection...")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
        .cardStyle()
    }

    /// The attribution to display, or nil when the quote is effectively
    /// anonymous (empty or "Unknown") so the byline is hidden entirely.
    static func displayAttribution(for quote: DailyQuote) -> String? {
        let trimmed = quote.attribution.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "unknown" else { return nil }
        return trimmed
    }
}
