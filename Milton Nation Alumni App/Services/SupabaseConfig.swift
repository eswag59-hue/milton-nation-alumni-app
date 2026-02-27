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

    // MARK: - Shared Client

    /// Shared Supabase client instance used throughout the app.
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
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
