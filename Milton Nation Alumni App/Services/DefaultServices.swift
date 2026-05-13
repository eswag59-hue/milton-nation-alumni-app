import Foundation

/// Single source of truth for which concrete service implementation is used in
/// each build configuration. Used as the default value of `init(authService:)`
/// and `init(dataService:)` parameters on ViewModels so that screens which
/// instantiate a ViewModel without dependency injection (e.g. SwiftUI `@State
/// private var viewModel = HomeViewModel()`) still get the correct service for
/// the build.
///
/// CRITICAL — this exists because every authenticated screen of the app used
/// to instantiate its ViewModel with the default `MockDataService()` /
/// `MockAuthService()` arguments. In Release builds (TestFlight, App Store)
/// that meant authenticated users saw mock data (Jordan Test, Taylor Sample,
/// Morgan Mock, Avery Testdata) instead of real Supabase content — a
/// guaranteed Apple-rejection bug. See commit history around build 4 for the
/// original audit finding.
///
/// In DEBUG builds we still want the mocks so Xcode previews + simulator runs
/// don't need a network. In Release we always hit Supabase.
enum DefaultServices {

    /// The shared `DataServiceProtocol` instance used by default.
    /// Single instance per app launch — internal Supabase client is itself a
    /// singleton, so reusing this avoids extra allocation churn.
    static let dataService: DataServiceProtocol = {
        #if DEBUG
        return MockDataService()
        #else
        return SupabaseDataService()
        #endif
    }()

    /// The shared `AuthServiceProtocol` instance used by default.
    static let authService: AuthServiceProtocol = {
        #if DEBUG
        return MockAuthService()
        #else
        return SupabaseAuthService()
        #endif
    }()
}
