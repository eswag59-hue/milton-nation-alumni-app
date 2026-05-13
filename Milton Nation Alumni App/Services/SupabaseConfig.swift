import Foundation
import Supabase

/// Central Supabase client configuration.
///
/// Credentials are embedded directly because the Supabase **anon key is a public key**
/// — security is enforced by Row Level Security (RLS) policies on the database,
/// not by keeping the anon key secret. This is the pattern recommended by Supabase
/// for mobile apps (https://supabase.com/docs/guides/getting-started/tutorials/with-swift).
///
/// The .xcconfig files still exist for local overrides; the hardcoded values below
/// are the live production credentials for Milton Nation Alumni App.
enum SupabaseConfig {

    // MARK: - Credentials

    private static let productionURL    = "https://hksxzuytcmqqwxmfjzdp.supabase.co"
    private static let productionAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhrc3h6dXl0Y21xcXd4bWZqemRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0MjM0MTQsImV4cCI6MjA4Njk5OTQxNH0.Z5SavNNIDWaWPDxyQ4fpXykgJm13gSaCpST355FPwUI"

    /// Supabase project URL. Reads from Info.plist first (xcconfig override), falls back
    /// to hardcoded production value.
    static let url: URL = {
        if let override = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
           !override.isEmpty, !override.contains("placeholder"),
           let url = URL(string: override) {
            #if DEBUG
            print("[SupabaseConfig] Using xcconfig URL override: \(override)")
            #endif
            return url
        }
        return URL(string: productionURL)!
    }()

    /// Supabase anonymous (public) key. Reads from Info.plist first (xcconfig override),
    /// falls back to hardcoded production value.
    static let anonKey: String = {
        if let override = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
           !override.isEmpty, !override.contains("placeholder") {
            return override
        }
        return productionAnonKey
    }()

    // MARK: - JSON Decoder / Encoder
    //
    // PostgREST's default decoder does NOT enable `.convertFromSnakeCase` — and our
    // Models (User, Post, Message, etc.) rely on Swift converting database columns
    // like `full_name` → `fullName`. Without this, decoding fails silently inside
    // `client.from(...).execute().value` and the LoginViewModel mislabels the error
    // as "Invalid email or password" because its catch block treats ALL throws as
    // a credential failure.
    //
    // We mirror PostgREST's built-in date-decoding strategy (handles both
    // `YYYY-MM-DD` dates and full ISO 8601 timestamps) and add the snake_case key
    // conversion on top. The encoder mirrors the inverse for writes.

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            // 1) ISO8601 with fractional seconds (most common from PostgREST):
            //    "2026-05-13T14:08:56.774807+00:00"
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFractional.date(from: string) { return date }
            // 2) ISO8601 without fractional seconds:
            //    "2026-05-13T14:08:56+00:00"
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) { return date }
            // 3) PostgreSQL sometimes emits short timezone "+00" (no colon, no minutes):
            //    "2026-05-13T14:08:56+00" — Apple's ISO8601DateFormatter rejects these.
            //    Normalise by appending ":00" then retry both ISO formats.
            if let normalised = Self.normaliseShortTimezone(string) {
                if let date = isoFractional.date(from: normalised) { return date }
                if let date = iso.date(from: normalised) { return date }
            }
            // 4) Date-only "YYYY-MM-DD" (PostgreSQL DATE column):
            //    sobriety_date, discharge_date, etc.
            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateOnly.date(from: string) { return date }
            // 5) Space-separated timestamp (some PG configurations):
            //    "2026-05-13 14:08:56+00"
            let spaceFmt = DateFormatter()
            spaceFmt.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
            spaceFmt.timeZone = TimeZone(secondsFromGMT: 0)
            spaceFmt.locale = Locale(identifier: "en_US_POSIX")
            if let date = spaceFmt.date(from: string) { return date }
            if let normalised = Self.normaliseShortTimezone(string),
               let date = spaceFmt.date(from: normalised) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(string)"
            )
        }
        return decoder
    }

    /// Convert PostgreSQL's short "+00" or "-05" timezone suffix into the
    /// fully-qualified "+00:00" / "-05:00" form that Apple's date formatters
    /// require. Returns nil if no conversion is needed.
    private static func normaliseShortTimezone(_ s: String) -> String? {
        // Match a trailing [+|-]HH that is NOT already followed by ":MM"
        // Examples that should normalise:
        //   "...+00"  →  "...+00:00"
        //   "...-05"  →  "...-05:00"
        // Examples that should NOT touch:
        //   "...+00:00", "...+0000", "...Z"
        guard let last3 = s.suffix(3).first.map({ _ in s.suffix(3) }) else { return nil }
        let chars = Array(last3)
        if chars.count == 3,
           (chars[0] == "+" || chars[0] == "-"),
           chars[1].isNumber, chars[2].isNumber {
            return s + ":00"
        }
        return nil
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    // MARK: - Shared Client

    /// Shared Supabase client instance used throughout the app.
    /// One client, one backend — facility isolation is handled by Postgres RLS policies,
    /// not by separate clients. See supabase/migrations/20260331_add_facility_isolation.sql.
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey,
        options: .init(
            db: .init(
                encoder: makeEncoder(),
                decoder: makeDecoder()
            ),
            auth: .init(
                emitLocalSessionAsInitialSession: true
            )
        )
    )

    // MARK: - Storage Buckets

    static let postMediaBucket   = "post-media"
    static let profilePhotosBucket = "profile-photos"
    static let chatMediaBucket   = "chat-media"

    // MARK: - Helpers

    /// Whether the app is connected to real Supabase credentials (not placeholder).
    static var isConfigured: Bool {
        let urlString = url.absoluteString
        return !urlString.contains("placeholder")
    }
}
