import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("AnalyticsService Tests")
struct AnalyticsServiceTests {

    @Test("track does not crash")
    func trackEvent() {
        AnalyticsService.shared.track(.screenView, properties: ["screen": "test"])
        // No crash = success
    }

    @Test("identify sets user properties")
    func identify() {
        let userId = UUID()
        AnalyticsService.shared.identify(userId: userId, role: "alumni")
        // No crash = success
    }

    @Test("reset does not crash")
    func reset() {
        AnalyticsService.shared.identify(userId: UUID(), role: "alumni")
        AnalyticsService.shared.reset()
        // No crash = success
    }

    @Test("trackScreen convenience works")
    func trackScreen() {
        AnalyticsService.shared.trackScreen("home")
        // No crash = success
    }

    @Test("flush does not crash")
    func flush() {
        AnalyticsService.shared.track(.login)
        AnalyticsService.shared.flush()
        // No crash = success
    }

    @Test("multiple rapid tracks don't crash")
    func rapidTracking() {
        for i in 0..<50 {
            AnalyticsService.shared.track(.screenView, properties: ["index": "\(i)"])
        }
    }
}
