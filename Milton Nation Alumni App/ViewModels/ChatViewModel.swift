import SwiftUI
import Supabase

@Observable
final class ChatViewModel {
    var conversations: [Conversation] = []
    var assignedStaff: [User] = []
    var messages: [ChatMessage] = []
    var messageText = ""
    var isLoading = false
    var errorMessage: String?
    var isUploadingMedia = false

    /// The current user's ID, set by the caller so Realtime can
    /// determine which messages are "from current user."
    var currentUserId: UUID?

    /// The conversation currently being viewed (for Realtime subscription).
    private var activeConversationId: UUID?

    // MARK: - Task Cancellation
    private var loadConversationsTask: Task<Void, Never>?
    private var loadMessagesTask: Task<Void, Never>?
    private var reconnectObserver: (any NSObjectProtocol)?

    let dataService: DataServiceProtocol
    private let cache = OfflineCacheService.shared

    init(dataService: DataServiceProtocol = DefaultServices.dataService) {
        self.dataService = dataService
        setupReconnectObserver()
    }

    deinit {
        if let observer = reconnectObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Load the caseload for a logged-in staff member (case manager / therapist):
    /// every conversation where they are the assigned staff, with the client as
    /// the display party. Mirrors loadConversations() but uses the staff-side fetch.
    func loadCaseload() {
        loadConversationsTask?.cancel()
        loadConversationsTask = Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                let convs = try await dataService.fetchClientConversations()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    conversations = convs
                    isLoading = false
                    cache.cacheConversations(convs)
                }
            } catch {
                guard !Task.isCancelled else { return }
                CrashReportingService.shared.recordError(error, context: "ChatViewModel.loadCaseload")
                await MainActor.run {
                    if let cached = cache.loadCachedConversations() {
                        conversations = cached
                    }
                    if conversations.isEmpty {
                        errorMessage = "Unable to load your clients. Please check your connection."
                    }
                    isLoading = false
                }
            }
        }
    }

    func loadConversations() {
        loadConversationsTask?.cancel()
        loadConversationsTask = Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                async let convResult = dataService.fetchConversations()
                async let staffResult = dataService.fetchAssignedStaff()
                let convs = try await convResult
                let staff = try await staffResult
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    conversations = convs
                    assignedStaff = staff
                    isLoading = false
                    // Cache for offline access
                    cache.cacheConversations(convs)
                    cache.cacheAssignedStaff(staff)
                }
            } catch {
                guard !Task.isCancelled else { return }
                CrashReportingService.shared.recordError(error, context: "ChatViewModel.loadConversations")
                await MainActor.run {
                    // Try offline cache fallback
                    if let cachedConvs = cache.loadCachedConversations() {
                        conversations = cachedConvs
                    }
                    if let cachedStaff = cache.loadCachedAssignedStaff() {
                        assignedStaff = cachedStaff
                    }
                    if conversations.isEmpty {
                        errorMessage = "Unable to load conversations. Please check your connection."
                    }
                    isLoading = false
                }
            }
        }
    }

    func loadMessages(conversationId: UUID) {
        activeConversationId = conversationId
        loadMessagesTask?.cancel()
        loadMessagesTask = Task {
            await MainActor.run { isLoading = true }
            do {
                let fetched = try await dataService.fetchMessages(conversationId: conversationId)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    messages = fetched
                    isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                CrashReportingService.shared.recordError(error, context: "ChatViewModel.loadMessages")
                await MainActor.run {
                    messages = []
                    isLoading = false
                }
            }
            // Subscribe to real-time messages for this conversation
            subscribeToMessages(conversationId: conversationId)
        }
    }

    func sendMessage(conversationId: UUID) {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        messageText = ""
        Task {
            // Run content through moderation pipeline
            let safetyResult = await ContentFilterService.shared.analyzeAndEscalate(content, feature: .chat)
            let moderationResult = ModerationResult(
                status: safetyResult.riskLevel == .highRisk ? .crisis
                      : safetyResult.riskLevel == .safe     ? .clean : .flagged,
                matchedKeywords: safetyResult.matches.map(\.keyword)
            )
            let msgStatus = ContentFilterService.shared.messageStatus(for: moderationResult)

            do {
                let msg = try await dataService.sendMessage(
                    conversationId: conversationId,
                    content: content,
                    type: .text,
                    status: msgStatus,
                    matchedKeywords: moderationResult.matchedKeywords
                )
                await MainActor.run {
                    // Only append if not already added by Realtime
                    if !messages.contains(where: { $0.id == msg.id }) {
                        messages.append(msg)
                    }
                }
            } catch {
                // Restore the typed text so the user can retry, surface the error
                await MainActor.run {
                    messageText = content
                    errorMessage = "Couldn't send message. Please try again."
                }
                CrashReportingService.shared.recordError(error, context: "ChatViewModel.sendMessage")
            }
        }
    }

    // MARK: - Media Upload

    /// Upload media data (image/file) to Supabase Storage and send as a message.
    func sendMedia(
        data: Data,
        type: MessageType,
        fileName: String,
        conversationId: UUID
    ) {
        Task {
            await MainActor.run { isUploadingMedia = true }

            var mediaURL: String?

            // Upload to Supabase Storage if configured
            if SupabaseConfig.isConfigured {
                do {
                    let fileExt = type == .image ? "jpg" : fileName.components(separatedBy: ".").last ?? "dat"
                    let storagePath = "chat/\(conversationId.uuidString)/\(UUID().uuidString).\(fileExt)"

                    try await SupabaseConfig.client.storage
                        .from("chat-media")
                        .upload(storagePath, data: data)

                    let publicURL = try SupabaseConfig.client.storage
                        .from("chat-media")
                        .getPublicURL(path: storagePath)

                    mediaURL = publicURL.absoluteString
                } catch {
                    CrashReportingService.shared.recordError(error, context: "ChatViewModel.sendMedia")
                    #if DEBUG
                    print("[ChatVM] ⚠️ Media upload failed: \(error.localizedDescription)")
                    #endif
                    // Abort — don't send a "Photo" message with no actual photo
                    await MainActor.run {
                        isUploadingMedia = false
                        errorMessage = "Couldn't upload media. Check your connection and try again."
                    }
                    return
                }
            } else {
                // Mock: generate a fake URL
                mediaURL = "mock://media/\(UUID().uuidString)"
            }

            let label = type == .image ? "Photo" : fileName
            do {
                let msg = try await dataService.sendMessage(
                    conversationId: conversationId,
                    content: label,
                    type: type,
                    status: .clean,
                    matchedKeywords: []
                )
                await MainActor.run {
                    var message = msg
                    message.mediaURL = mediaURL
                    if !messages.contains(where: { $0.id == message.id }) {
                        messages.append(message)
                    }
                    isUploadingMedia = false
                }
            } catch {
                await MainActor.run {
                    isUploadingMedia = false
                    errorMessage = "Couldn't send media. Please try again."
                }
                CrashReportingService.shared.recordError(error, context: "ChatViewModel.sendMedia.sendMessage")
            }
        }
    }

    // MARK: - Realtime

    /// Re-subscribes to the active conversation when the app returns to foreground.
    private func setupReconnectObserver() {
        reconnectObserver = NotificationCenter.default.addObserver(
            forName: RealtimeService.reconnectNeeded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let conversationId = self.activeConversationId else { return }
            self.subscribeToMessages(conversationId: conversationId)
        }
    }

    /// Subscribe to live message updates for the active conversation.
    private func subscribeToMessages(conversationId: UUID) {
        guard SupabaseConfig.isConfigured else { return }
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        RealtimeService.shared.subscribeToMessages(
            conversationId: conversationId
        ) { [weak self] message in
            guard let self else { return }
            // Avoid duplicates (e.g., messages we sent ourselves)
            if !self.messages.contains(where: { $0.id == message.id }) {
                var newMessage = message
                // Determine if it's from the current user
                // (the Realtime payload won't have isFromCurrentUser set)
                if let uid = self.currentUserId {
                    newMessage.isFromCurrentUser = message.senderId == uid
                }
                self.messages.append(newMessage)
            }
        }
    }

    /// Unsubscribe when leaving the conversation view.
    func leaveConversation() {
        RealtimeService.shared.unsubscribeFromMessages()
        activeConversationId = nil
    }

    // MARK: - Cleanup

    func cancelTasks() {
        loadConversationsTask?.cancel()
        loadMessagesTask?.cancel()
        loadConversationsTask = nil
        loadMessagesTask = nil
    }
}
