import Foundation
import Supabase

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
    private var reconnectObserver: (any NSObjectProtocol)?

    private init() {
        // Auto-flush queued events when the device reconnects to the network
        reconnectObserver = NotificationCenter.default.addObserver(
            forName: NetworkMonitor.didReconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flush()
        }
    }

    deinit {
        if let observer = reconnectObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

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
        // Combine in-memory buffer with persisted offline queue
        let persisted = Self.loadPersistedQueue()
        let combined = persisted + eventBuffer
        eventBuffer = []
        Self.savePersistedQueue([])  // clear persisted queue while we attempt send

        guard !combined.isEmpty else { return }

        #if DEBUG
        print("[Analytics] Flushing \(combined.count) events (buffered + persisted)")
        #endif

        guard SupabaseConfig.isConfigured else {
            // Re-persist if not configured so we don't lose events
            Self.savePersistedQueue(combined)
            return
        }

        let userProps = userProperties
        Task {
            let success = await Self.sendToSupabase(combined, userProperties: userProps)
            if !success {
                // Network failure — re-persist the events for retry on next flush
                // Cap at maxPersistedSize to prevent unbounded growth.
                let toRetain = Array(combined.suffix(Self.maxPersistedSize))
                Self.savePersistedQueue(toRetain)
            }
        }
    }

    /// Returns true on successful send, false otherwise.
    @discardableResult
    private static func sendToSupabase(
        _ events: [AnalyticsEvent],
        userProperties: [String: String]
    ) async -> Bool {
        let userId = userProperties["user_id"].flatMap { UUID(uuidString: $0) }
        let role   = userProperties["role"]

        let records = events.map { event in
            AnalyticsRecord(
                userId: userId,
                eventName: event.name,
                properties: event.properties,
                role: role
            )
        }

        do {
            try await SupabaseConfig.client
                .from("analytics_events")
                .insert(records)
                .execute()
            return true
        } catch {
            #if DEBUG
            print("[Analytics] Flush failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Offline Queue (UserDefaults persistence)

    /// Cap on how many events we'll retry. Once exceeded, oldest events are dropped.
    private static let maxPersistedSize = 1000
    private static let queueKey = "analytics_offline_queue_v1"

    private static func loadPersistedQueue() -> [AnalyticsEvent] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return [] }
        do {
            return try JSONDecoder().decode([AnalyticsEvent].self, from: data)
        } catch {
            return []
        }
    }

    private static func savePersistedQueue(_ events: [AnalyticsEvent]) {
        guard !events.isEmpty else {
            UserDefaults.standard.removeObject(forKey: queueKey)
            return
        }
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            #if DEBUG
            print("[Analytics] Failed to persist offline queue: \(error.localizedDescription)")
            #endif
        }
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

private struct AnalyticsEvent: Codable, Sendable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}

// MARK: - Supabase Insert Record

private struct AnalyticsRecord: Encodable {
    let userId: UUID?
    let eventName: String
    let properties: [String: String]
    let role: String?

    enum CodingKeys: String, CodingKey {
        case userId    = "user_id"
        case eventName = "event_name"
        case properties
        case role
    }
}
