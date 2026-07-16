import SwiftUI
import PhotosUI

struct CreatePostSheet: View {
    @Bindable var viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var showCamera = false

    private var isSubmitDisabled: Bool {
        let trimmed = viewModel.newPostContent.trimmingCharacters(in: .whitespacesAndNewlines)
        // Also disable while a submit is in flight so a second tap can't create
        // a duplicate post.
        return trimmed.isEmpty || trimmed.count > 1000 || viewModel.isPostingInFlight
    }

    @FocusState private var contentFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 20) {
                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accentLime)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PostCategory.allCases, id: \.self) { category in
                                Button {
                                    viewModel.newPostCategory = category
                                } label: {
                                    Text("\(category.emoji) \(category.displayName)")
                                        .font(.subheadline)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(viewModel.newPostCategory == category ? .white : AppTheme.textPrimary)
                                        .background(viewModel.newPostCategory == category ? AppTheme.accent : AppTheme.background)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's on your mind?")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accentLime)

                    TextEditor(text: $viewModel.newPostContent)
                        .focused($contentFocused)
                        .foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .strokeBorder(AppTheme.divider)
                        )
                        .contentSafetyOverlay(
                            text: $viewModel.newPostContent,
                            userId: appViewModel.currentUser?.id,
                            feature: .communityPost
                        )

                    HStack {
                        Spacer()
                        Text("\(viewModel.newPostContent.count)/1000")
                            .font(.caption)
                            .foregroundStyle(viewModel.newPostContent.count > 1000 ? .red : AppTheme.textSecondary)
                    }
                }

                // Media attachment bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attach Media")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accentLime)

                    HStack(spacing: 12) {
                        // Photo — opens gallery, photos only
                        Button {
                            showPhotoPicker = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "photo.fill")
                                    .font(.title3)
                                Text("Photo")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(viewModel.selectedMediaType == .image ? .white : AppTheme.accent)
                            .background(viewModel.selectedMediaType == .image ? AppTheme.accent : AppTheme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }

                        // Camera — opens live camera
                        Button {
                            showCamera = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                Text("Camera")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(AppTheme.accent)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }

                        // Video — opens gallery, videos only
                        Button {
                            showVideoPicker = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                    .font(.title3)
                                Text("Video")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(viewModel.selectedMediaType == .video ? .white : AppTheme.accent)
                            .background(viewModel.selectedMediaType == .video ? AppTheme.accent : AppTheme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }
                    }

                    // Multi-photo preview — a horizontal strip of every selected
                    // photo, each removable. Re-tapping "Photo" adds more (up to 5).
                    if !viewModel.selectedImageDatas.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(viewModel.selectedImageDatas.count) photo\(viewModel.selectedImageDatas.count == 1 ? "" : "s") attached — tap ✕ to remove, tap Photo to add more")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(viewModel.selectedImageDatas.enumerated()), id: \.offset) { index, data in
                                        if let uiImage = UIImage(data: data) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 72, height: 72)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                Button {
                                                    viewModel.selectedImageDatas.remove(at: index)
                                                    viewModel.selectedMediaData = viewModel.selectedImageDatas.first
                                                    if viewModel.selectedImageDatas.isEmpty {
                                                        viewModel.selectedMediaType = nil
                                                    }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.white)
                                                        .background(Circle().fill(.black.opacity(0.5)))
                                                }
                                                .padding(2)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    } else if viewModel.selectedMediaType == .video {
                        // Single video preview.
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.background)
                                .frame(width: 60, height: 60)
                                .overlay { Image(systemName: "video.fill").foregroundStyle(AppTheme.accent) }
                            Text("Video attached")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Button {
                                viewModel.selectedMediaType = nil
                                viewModel.selectedMediaData = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    }
                }

                Button {
                    contentFocused = false        // dismiss keyboard before submit
                    viewModel.createPost()
                } label: {
                    Text("Submit Post")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(
                            isSubmitDisabled ? AppTheme.textSecondary : AppTheme.accent
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .disabled(isSubmitDisabled)

                // Extra breathing room so the Submit button stays comfortably
                // above the home indicator + any keyboard inset.
                Color.clear.frame(height: 60)
            }
            .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                // Keyboard toolbar with "Done" so the user can dismiss the
                // keyboard if they can't reach Submit Post.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { contentFocused = false }
                        .fontWeight(.semibold)
                }
            }
            // Photo picker — up to 5 images per post (multi-photo).
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItems,
                          maxSelectionCount: 5, matching: .images)
            .onChange(of: selectedPhotoItems) {
                guard !selectedPhotoItems.isEmpty else { return }
                let items = selectedPhotoItems
                Task {
                    var datas: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty {
                            datas.append(data)
                        }
                    }
                    await MainActor.run {
                        if !datas.isEmpty {
                            viewModel.selectedMediaType = .image
                            // Append to any already-picked photos (re-picking adds more).
                            viewModel.selectedImageDatas.append(contentsOf: datas)
                            viewModel.selectedMediaData = viewModel.selectedImageDatas.first
                            // Clear any video selection — a post is photos OR a video.
                            if viewModel.selectedMediaType == .image { }
                        }
                    }
                    await MainActor.run { selectedPhotoItems = [] }
                }
            }
            // Video picker — videos only
            .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideoItem, matching: .videos)
            .onChange(of: selectedVideoItem) {
                if let item = selectedVideoItem {
                    viewModel.selectedMediaType = .video
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty {
                            await MainActor.run { viewModel.selectedMediaData = data }
                        }
                    }
                    selectedVideoItem = nil
                }
            }
            // Camera — live device camera (photo + video)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(mode: .photoAndVideo) { data, isVideo in
                    showCamera = false
                    viewModel.selectedMediaType = isVideo ? .video : .image
                    if isVideo {
                        viewModel.selectedImageDatas = []
                        viewModel.selectedMediaData = data
                    } else {
                        // A camera photo joins the multi-photo set.
                        viewModel.selectedImageDatas.append(data)
                        viewModel.selectedMediaData = viewModel.selectedImageDatas.first
                    }
                } onCancel: {
                    showCamera = false
                }
                .ignoresSafeArea()
            }
        }
    }
}
