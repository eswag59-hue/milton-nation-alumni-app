import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatDetailScreen: View {
    let staffName: String
    let staffRole: UserRole
    let conversationId: UUID
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = ChatViewModel()
    @State private var showAttachmentOptions = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showVideoCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.isFromCurrentUser
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Upload progress indicator
            if viewModel.isUploadingMedia {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Uploading media\u{2026}")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(AppTheme.background)
            }

            // Input bar
            HStack(spacing: 8) {
                // Attachment button
                Button {
                    showAttachmentOptions = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accent)
                }
                .disabled(viewModel.isUploadingMedia)

                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...4)
                    .contentSafetyOverlay(
                        text: $viewModel.messageText,
                        userId: appViewModel.currentUser?.id,
                        feature: .chat
                    )

                Button {
                    viewModel.sendMessage(conversationId: conversationId)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.accent
                        )
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(AppTheme.cardBackground)

            // Emergency footer
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.struggling)
                Text("Need immediate help?")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textPrimary)
                Button("Call 988") {
                    PhoneService.call("988")
                }
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.struggling)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(AppTheme.strugglingLight.opacity(0.5))
        }
        .navigationTitle(staffName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages(conversationId: conversationId)
        }
        .onDisappear {
            viewModel.leaveConversation()
            viewModel.cancelTasks()
        }
        .confirmationDialog("Attach Media", isPresented: $showAttachmentOptions) {
            Button("Library") {
                showImagePicker = true
            }
            Button("Camera") {
                showCamera = true
            }
            Button("Video") {
                showVideoCamera = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .any(of: [.images, .videos]))
        .onChange(of: selectedPhotoItem) {
            if let item = selectedPhotoItem {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        // Check if video was selected based on content type
                        let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) })
                        viewModel.sendMedia(
                            data: data,
                            type: isVideo ? .file : .image,
                            fileName: isVideo ? "video.mp4" : "photo.jpg",
                            conversationId: conversationId
                        )
                    }
                    selectedPhotoItem = nil
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(mode: .photo) { data, isVideo in
                showCamera = false
                viewModel.sendMedia(
                    data: data,
                    type: isVideo ? .file : .image,
                    fileName: isVideo ? "video.mp4" : "camera_photo.jpg",
                    conversationId: conversationId
                )
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showVideoCamera) {
            CameraPickerView(mode: .video) { data, _ in
                showVideoCamera = false
                viewModel.sendMedia(
                    data: data,
                    type: .file,
                    fileName: "video.mp4",
                    conversationId: conversationId
                )
            } onCancel: {
                showVideoCamera = false
            }
            .ignoresSafeArea()
        }
    }

}


// MARK: - Legacy Camera Placeholder (simulator fallback)

struct CameraPlaceholderView: View {
    var onCapture: () -> Void

    var body: some View {
        CameraPickerView(mode: .photoAndVideo) { _, _ in
            onCapture()
        } onCancel: {
            onCapture()
        }
        .ignoresSafeArea()
    }
}
