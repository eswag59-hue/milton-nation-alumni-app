import Foundation
import Supabase

/// Centralized Supabase Realtime subscription manager.
///
/// Provides live data updates for:
/// - Chat messages (per-conversation)
/// - Community posts (new approved posts)
/// - Admin notifications (new pending/flagged posts)
///
/// Usage:
///   RealtimeService.shared.subscribeToMessages(conversationId: id) { message in ... }
///   RealtimeService.shared.unsubscribeFromMessages()
final class RealtimeService {

    static let shared = RealtimeService()

    private let client = SupabaseConfig.client
    private var messageChannel: RealtimeChannelV2?
    private var postChannel: RealtimeChannelV2?
    private var adminPostChannel: RealtimeChannelV2?
    private var conversationChannel: RealtimeChannelV2?
    private var userProfileChannel: RealtimeChannelV2?
    private var pendingUsersChannel: RealtimeChannelV2?

    private init() {}

    // MARK: - Chat Messages (Real-time)

    /// Subscribe to new messages in a specific conversation.
    func subscribeToMessages(
        conversationId: UUID,
        onInsert: @escaping @Sendable (ChatMessage) -> Void
    ) {
        unsubscribeFromMessages()

        let channel = client.realtimeV2.channel("messages-\(conversationId.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("conversation_id", value: conversationId)
        )

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                CrashReportingService.shared.recordError(error, context: "RealtimeService.subscribeToMessages")
                #if DEBUG
                print("[RealtimeService] ⚠️ messages channel error: \(error)")
                #endif
                return
            }

            for await insertion in insertions {
                do {
                    let message = try insertion.decodeRecord(as: ChatMessage.self, decoder: JSONDecoder.supabase)
                    await MainActor.run { onInsert(message) }
                } catch {
                    #if DEBUG
                    print("[RealtimeService] ⚠️ Failed to decode message: \(error)")
                    #endif
                }
            }
        }

        messageChannel = channel
    }

    /// Stop listening for messages.
    func unsubscribeFromMessages() {
        guard let channel = messageChannel else { return }
        Task { await channel.unsubscribe() }
        messageChannel = nil
    }

    // MARK: - Community Posts (Real-time)

    /// Subscribe to new approved posts appearing in the community feed.
    func subscribeToPosts(
        onInsert: @escaping @Sendable (CommunityPost) -> Void,
        onUpdate: @escaping @Sendable (CommunityPost) -> Void
    ) {
        unsubscribeFromPosts()

        let channel = client.realtimeV2.channel("community-posts")

        let insertions = channel.postgresChange(InsertAction.self, schema: "public", table: "posts")
        let updates    = channel.postgresChange(UpdateAction.self, schema: "public", table: "posts")

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                CrashReportingService.shared.recordError(error, context: "RealtimeService.subscribeToPosts")
                #if DEBUG
                print("[RealtimeService] ⚠️ posts channel error: \(error)")
                #endif
                return
            }

            Task {
                for await insertion in insertions {
                    do {
                        let post = try insertion.decodeRecord(as: CommunityPost.self, decoder: JSONDecoder.supabase)
                        if post.status == .approved {
                            await MainActor.run { onInsert(post) }
                        }
                    } catch {
                        #if DEBUG
                        print("[RealtimeService] ⚠️ Failed to decode inserted post: \(error)")
                        #endif
                    }
                }
            }

            Task {
                for await update in updates {
                    do {
                        let post = try update.decodeRecord(as: CommunityPost.self, decoder: JSONDecoder.supabase)
                        await MainActor.run { onUpdate(post) }
                    } catch {
                        #if DEBUG
                        print("[RealtimeService] ⚠️ Failed to decode updated post: \(error)")
                        #endif
                    }
                }
            }
        }

        postChannel = channel
    }

    /// Stop listening for community post changes.
    func unsubscribeFromPosts() {
        guard let channel = postChannel else { return }
        Task { await channel.unsubscribe() }
        postChannel = nil
    }

    // MARK: - Admin: Pending / Flagged Posts (Real-time)

    /// Subscribe to new posts that need admin review.
    func subscribeToAdminPosts(
        onNewPending: @escaping @Sendable (CommunityPost) -> Void,
        onStatusChange: @escaping @Sendable (CommunityPost) -> Void
    ) {
        unsubscribeFromAdminPosts()

        let channel = client.realtimeV2.channel("admin-posts")

        let insertions = channel.postgresChange(InsertAction.self, schema: "public", table: "posts")
        let updates    = channel.postgresChange(UpdateAction.self, schema: "public", table: "posts")

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                CrashReportingService.shared.recordError(error, context: "RealtimeService.subscribeToAdminPosts")
                #if DEBUG
                print("[RealtimeService] ⚠️ admin-posts channel error: \(error)")
                #endif
                return
            }

            Task {
                for await insertion in insertions {
                    do {
                        let post = try insertion.decodeRecord(as: CommunityPost.self, decoder: JSONDecoder.supabase)
                        if post.status != .approved {
                            await MainActor.run { onNewPending(post) }
                        }
                    } catch {
                        #if DEBUG
                        print("[RealtimeService] ⚠️ Failed to decode admin post: \(error)")
                        #endif
                    }
                }
            }

            Task {
                for await update in updates {
                    do {
                        let post = try update.decodeRecord(as: CommunityPost.self, decoder: JSONDecoder.supabase)
                        await MainActor.run { onStatusChange(post) }
                    } catch {
                        #if DEBUG
                        print("[RealtimeService] ⚠️ Failed to decode admin post update: \(error)")
                        #endif
                    }
                }
            }
        }

        adminPostChannel = channel
    }

    /// Stop listening for admin post notifications.
    func unsubscribeFromAdminPosts() {
        guard let channel = adminPostChannel else { return }
        Task { await channel.unsubscribe() }
        adminPostChannel = nil
    }

    // MARK: - Conversation List Updates

    /// Subscribe to conversation updates for a user.
    func subscribeToConversations(
        userId: UUID,
        onUpdate: @escaping @Sendable (UUID, String?, Date?, Int) -> Void
    ) {
        unsubscribeFromConversations()

        let channel = client.realtimeV2.channel("conversations-\(userId.uuidString)")

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "conversations",
            filter: .eq("user_id", value: userId)
        )

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                CrashReportingService.shared.recordError(error, context: "RealtimeService.subscribeToConversations")
                #if DEBUG
                print("[RealtimeService] ⚠️ conversations channel error: \(error)")
                #endif
                return
            }

            for await update in updates {
                do {
                    let row = try update.decodeRecord(as: ConversationUpdateRow.self, decoder: JSONDecoder.supabase)
                    await MainActor.run {
                        onUpdate(row.id, row.lastMessage, row.lastMessageAt, row.unreadCount)
                    }
                } catch {
                    #if DEBUG
                    print("[RealtimeService] ⚠️ Failed to decode conversation update: \(error)")
                    #endif
                }
            }
        }

        conversationChannel = channel
    }

    /// Stop listening for conversation updates.
    func unsubscribeFromConversations() {
        guard let channel = conversationChannel else { return }
        Task { await channel.unsubscribe() }
        conversationChannel = nil
    }

    // MARK: - User Profile Status (approval monitoring)

    /// Subscribe to profile status changes for a specific user.
    func subscribeToUserProfile(
        userId: UUID,
        onStatusChange: @escaping @Sendable (UserStatus) -> Void
    ) {
        unsubscribeFromUserProfile()

        let channel = client.realtimeV2.channel("profile-\(userId.uuidString)")

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles",
            filter: .eq("id", value: userId)
        )

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                CrashReportingService.shared.recordError(error, context: "RealtimeService.subscribeToUserProfile")
                #if DEBUG
                print("[RealtimeService] ⚠️ profile channel error: \(error)")
                #endif
                return
            }

            for await update in updates {
                do {
                    let row = try update.decodeRecord(as: ProfileStatusRow.self, decoder: JSONDecoder.supabase)
                    if let status = UserStatus(rawValue: row.status) {
                        await MainActor.run { onStatusChange(status) }
                    }
                } catch {
                    #if DEBUG
                    print("[RealtimeService] ⚠️ Failed to decode profile update: \(error)")
                    #endif
                }
            }
        }

        userProfileChannel = channel
    }

    func unsubscribeFromUserProfile() {
        guard let channel = userProfileChannel else { return }
        Task { await channel.unsubscribe() }
        userProfileChannel = nil
    }

    // MARK: - Pending Users (admin real-time alerts)

    /// Subscribe to new users registering with pending status.
    func subscribeToPendingUsers(
        onNewUser: @escaping @Sendable (User) -> Void
    ) {
        unsubscribeFromPendingUsers()

        let channel = client.realtimeV2.channel("pending-users")

        // Server-side filter — only emit rows where status=pending. Without
        // this, every new signup wakes every authenticated admin's WebSocket
        // and decodes a full profile row before the post-filter drops it.
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "profiles",
            filter: "status=eq.pending"
        )

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                CrashReportingService.shared.recordError(error, context: "RealtimeService.subscribeToPendingUsers")
                #if DEBUG
                print("[RealtimeService] ⚠️ pending-users channel error: \(error)")
                #endif
                return
            }

            for await insertion in insertions {
                do {
                    let user = try insertion.decodeRecord(as: User.self, decoder: JSONDecoder.supabase)
                    if user.status == .pending {
                        await MainActor.run { onNewUser(user) }
                    }
                } catch {
                    #if DEBUG
                    print("[RealtimeService] ⚠️ Failed to decode new pending user: \(error)")
                    #endif
                }
            }
        }

        pendingUsersChannel = channel
    }

    func unsubscribeFromPendingUsers() {
        guard let channel = pendingUsersChannel else { return }
        Task { await channel.unsubscribe() }
        pendingUsersChannel = nil
    }

    // MARK: - Disconnect All

    /// Unsubscribe from all active channels. Call on logout.
    func disconnectAll() {
        unsubscribeFromMessages()
        unsubscribeFromPosts()
        unsubscribeFromAdminPosts()
        unsubscribeFromConversations()
        unsubscribeFromUserProfile()
        unsubscribeFromPendingUsers()
    }

    // MARK: - Reconnect Notification

    /// Posted when the app returns to the foreground while the user is authenticated.
    /// ViewModels that hold active Realtime subscriptions should observe this notification
    /// and re-call their `subscribe…` methods so that any WebSocket connections that
    /// dropped during backgrounding are re-established.
    ///
    /// Example:
    /// ```swift
    /// .onReceive(NotificationCenter.default.publisher(for: RealtimeService.reconnectNeeded)) {
    ///     viewModel.setupSubscriptions()
    /// }
    /// ```
    static let reconnectNeeded = Notification.Name("RealtimeServiceReconnectNeeded")

    /// Call this when the app comes to the foreground (authenticated).
    /// It disconnects stale channels and notifies all observers to re-subscribe.
    func reconnectIfNeeded() {
        disconnectAll()
        NotificationCenter.default.post(name: RealtimeService.reconnectNeeded, object: nil)
    }

    // MARK: - Subscription Retry with Exponential Backoff

    /// Call from inside a `subscribe…` task when `subscribeWithError` throws.
    /// Sleeps for an exponentially-growing delay (capped at 30s) and posts the
    /// reconnect notification so the caller's outer subscribe layer is invoked again.
    /// Returns immediately if attempt count exceeds the cap (8 retries ≈ 8.5 min total).
    @Sendable
    static func backoffAndRetry(attempt: Int) async {
        guard attempt < 8 else {
            #if DEBUG
            print("[RealtimeService] ⚠️ Giving up after \(attempt) reconnect attempts")
            #endif
            return
        }
        // 1s, 2s, 4s, 8s, 16s, 30s, 30s, 30s
        let delay = min(pow(2.0, Double(attempt)), 30.0)
        #if DEBUG
        print("[RealtimeService] retry attempt #\(attempt + 1) in \(delay)s")
        #endif
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        await MainActor.run {
            NotificationCenter.default.post(name: RealtimeService.reconnectNeeded, object: nil)
        }
    }
}

// MARK: - Helper Decodable for Conversation Updates

nonisolated private struct ConversationUpdateRow: Decodable, Sendable {
    let id: UUID
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
    }
}

nonisolated private struct ProfileStatusRow: Decodable, Sendable {
    let status: String
}

// MARK: - JSONDecoder Extension for Supabase

extension JSONDecoder {
    /// A decoder configured to match Supabase's default date format.
    static let supabase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: dateString) { return date }

            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: dateString) { return date }

            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            if let date = dateOnly.date(from: dateString) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }()
}
