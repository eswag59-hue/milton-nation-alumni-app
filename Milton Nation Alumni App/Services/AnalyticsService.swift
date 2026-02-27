import Foundation

/// Lightweight analytics foundation for tracking user engagement.
///
/// Designed to be pluggable — swap the backend implementation without
/// changing call sites. Currently logs to console and persists events
/// to a local buffer. In production, flush to your analytics backend
/// (Mixpanel, Amplitude, PostHog, or a Supabase `analytics_events` table).
///
/// Usage:
/// ```swift
/// AnalyticsService.shared.track(.screenView, properties: ["screen": "home"])
/// ```
final class AnalyticsService: @unchecked Sendable {

    static let shared = AnalyticsService()

    /// Maximum events to buffer before auto-flushing.
    private let maxBufferSize = 100

    /// Buffered events waiting to be sent.
    private var eventBuffer: [AnalyticsEvent] = []

    /// User properties set on login.
    private var userProperties: [String: String] = [:]

    private let queue = DispatchQueue(label: "com.miltonalumni.analytics", qos: .utility)

    private init() {}

    // MARK: - User Identity

    /// Set the current user for analytics.
    func identify(userId: UUID, role: String) {
        queue.async { [self] in
            userProperties = [
                "user_id": userId.uuidString,
                "role": role
            ]
        }
    }

    /// Clear user identity on logout.
    func reset() {
        queue.async { [self] in
            userProperties = [:]
            eventBuffer = []
        }
    }

    // MARK: - Track Events

    /// Track an analytics event with optional properties.
    func track(_ event: EventName, properties: [String: String] = [:]) {
        queue.async { [self] in
            let analyticsEvent = AnalyticsEvent(
                name: event.rawValue,
                properties: properties.merging(userProperties) { a, _ in a },
                timestamp: Date()
            )

            eventBuffer.append(analyticsEvent)

            #if DEBUG
            print("[Analytics] \(event.rawValue) \(properties.isEmpty ? "" : properties.description)")
            #endif

            // Auto-flush when buffer is full
            if eventBuffer.count >= maxBufferSize {
                flushInternal()
            }
        }
    }

    // MARK: - Screen Tracking

    /// Convenience for screen view tracking.
    func trackScreen(_ screenName: String) {
        track(.screenView, properties: ["screen": screenName])
    }

    // MARK: - Flush

    /// Send all buffered events to the backend.
    func flush() {
        queue.async { [self] in
            flushInternal()
        }
    }

    private func flushInternal() {
        guard !eventBuffer.isEmpty else { return }
        let events = eventBuffer
        eventBuffer = []

        // Analytics backend integration point:
        // POST to Supabase Edge Function, Mixpanel, or Amplitude
        #if DEBUG
        print("[Analytics] Flushed \(events.count) events")
        #endif
    }

    // MARK: - Event Names

    enum EventName: String {
        // Core
        case appLaunch = "app_launch"
        case screenView = "screen_view"
        case login
        case logout

        // Community
        case postCreated = "post_created"
        case postLiked = "post_liked"
        case commentAdded = "comment_added"

        // Chat
        case messageSent = "message_sent"
        case mediaUploaded = "media_uploaded"

        // Meetings
        case meetingViewed = "meeting_viewed"
        case meetingRSVP = "meeting_rsvp"
        case nearbyMeetingSearch = "nearby_meeting_search"
        case directionsOpened = "directions_opened"

        // Recovery
        case sobrietyDateReset = "sobriety_date_reset"
        case strugglingModeEntered = "struggling_mode_entered"
        case crisisResourceCalled = "crisis_resource_called"

        // Milestones
        case milestoneReached = "milestone_reached"
        case badgeEarned = "badge_earned"

        // Settings
        case settingsChanged = "settings_changed"
        case notificationPermissionGranted = "notification_permission_granted"

        // Errors
        case error
        case networkError = "network_error"
    }
}

// MARK: - Analytics Event Model

private struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}
