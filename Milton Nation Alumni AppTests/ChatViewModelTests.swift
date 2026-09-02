import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("ChatViewModel Tests")
struct ChatViewModelTests {

    /// Polls until `cond` holds (or the deadline passes), instead of sleeping a
    /// fixed interval. Fixed 1.2s sleeps raced the ViewModel's async Tasks on
    /// slow shared CI simulators and made these tests flaky.
    private func waitUntil(timeout: Double = 10, _ cond: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !cond() && Date() < deadline {
            try await Task.sleep(for: .milliseconds(100))
            await Task.yield()
        }
    }

    // MARK: - Conversations

    @Test("loadConversations populates conversations array")
    func loadConversations() async throws {
        let vm = ChatViewModel()
        vm.loadConversations()
        try await waitUntil { !vm.conversations.isEmpty && !vm.isLoading }
        #expect(!vm.conversations.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test("loadConversations populates assignedStaff")
    func loadAssignedStaff() async throws {
        let vm = ChatViewModel()
        vm.loadConversations()
        try await waitUntil { !vm.assignedStaff.isEmpty }
        #expect(!vm.assignedStaff.isEmpty)
    }

    // MARK: - Messages

    @Test("loadMessages loads messages for a conversation")
    func loadMessages() async throws {
        let vm = ChatViewModel()
        let conversationId = MockData.conversations.first?.id ?? UUID()
        vm.loadMessages(conversationId: conversationId)
        try await waitUntil { !vm.isLoading }
        #expect(!vm.isLoading)
    }

    @Test("sendMessage clears messageText")
    func sendMessageClearsText() async throws {
        let vm = ChatViewModel()
        vm.messageText = "Hello"
        let conversationId = UUID()
        vm.sendMessage(conversationId: conversationId)
        // messageText should be cleared immediately
        #expect(vm.messageText.isEmpty)
    }

    @Test("sendMessage does nothing with empty text")
    func sendEmptyMessage() async throws {
        let vm = ChatViewModel()
        vm.messageText = "   "
        let initialCount = vm.messages.count
        vm.sendMessage(conversationId: UUID())
        // Negative assertion: a short fixed window is the best we can do.
        try await Task.sleep(for: .milliseconds(300))
        #expect(vm.messages.count == initialCount)
    }

    // MARK: - Media Upload State

    @Test("isUploadingMedia starts as false")
    func uploadingMediaInitialState() {
        let vm = ChatViewModel()
        #expect(!vm.isUploadingMedia)
    }

    // MARK: - Leave Conversation

    @Test("leaveConversation does not crash")
    func leaveConversation() {
        let vm = ChatViewModel()
        vm.leaveConversation() // Should not crash
    }

    // MARK: - Task Cancellation

    @Test("cancelTasks does not crash")
    func cancelTasks() {
        let vm = ChatViewModel()
        vm.loadConversations()
        vm.cancelTasks() // Should not crash
    }
}
