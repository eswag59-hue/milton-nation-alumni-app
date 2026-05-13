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
            // Try full ISO8601 with fractional seconds first
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFractional.date(from: string) { return date }
            // Fall back to ISO8601 without fractional seconds
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) { return date }
            // Fall back to date-only "YYYY-MM-DD" (PostgreSQL DATE column)
            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateOnly.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(string)"
            )
        }
        return decoder
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
