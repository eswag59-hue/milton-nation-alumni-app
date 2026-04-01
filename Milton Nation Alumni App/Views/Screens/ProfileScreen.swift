import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    let user: User
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel: ProfileViewModel
    @State private var showDeleteConfirmation = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: Image?

    init(user: User) {
        self.user = user
        self._viewModel = State(initialValue: ProfileViewModel(user: user))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Logo header
                MiltonLogoView(size: .small)
                    .padding(.top, 8)

                // Profile header
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 36))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                            }
                            // Camera badge
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 2, y: 2)
                        }
                    }
                    .onChange(of: selectedPhotoItem) {
                        Task {
                            if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                                // Upload to Supabase Storage
                                viewModel.uploadProfilePhoto(imageData: data)
                            }
                        }
                    }
                    .accessibilityLabel("Change profile photo")
                    .accessibilityHint("Double tap to choose a photo from your library")
                    Text(user.fullName)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    // Photo upload status
                    if viewModel.isUploadingPhoto {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Uploading photo\u{2026}")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    if let error = viewModel.photoUploadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppTheme.struggling)
                    }
                }

                // Points & Badges — ABOVE personal info
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Points & Badges")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(user.totalPoints) pts")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }

                    if let nextBadge = viewModel.nextBadge {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Next: \(nextBadge.emoji) \(nextBadge.name)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text("\(user.totalPoints)/\(nextBadge.pointsRequired)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.background)
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.accent)
                                        .frame(width: geo.size.width * viewModel.progressToNextBadge, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    } else if !viewModel.badges.isEmpty {
                        // All badges earned 🎉
                        HStack(spacing: 10) {
                            Text("🏆")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("All badges earned!")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.accent)
                                Text("You've reached the top. Legend status achieved.")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Badges grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()), GridItem(.flexible()),
                        GridItem(.flexible()), GridItem(.flexible()),
                        GridItem(.flexible()), GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(viewModel.badges) { badge in
                            BadgeView(
                                badge: badge,
                                isEarned: viewModel.earnedBadgeIds.contains(badge.id)
                            )
                        }
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)

                // Badge Legend
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("How to Earn Badges")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("Goal: 5,000 pts")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.accent)
                    }

                    legendRow(emoji: "🔥", title: "Daily Login", description: "Log in once per day", points: 10)
                    legendRow(emoji: "📝", title: "Community Post", description: "Share in the community", points: 15)
                    legendRow(emoji: "❤️", title: "Give Support", description: "Like a peer's post", points: 5)
                    legendRow(emoji: "🏆", title: "Sobriety Milestone", description: "Hit a recovery milestone", points: 50)
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)

                // Personal Info card
                VStack(spacing: 0) {
                    infoRow(icon: "phone.fill", label: "Phone", value: user.phone)
                    Divider().padding(.leading, 52)
                    infoRow(icon: "calendar", label: "Sobriety Date", value: user.sobrietyDate.formatted(date: .abbreviated, time: .omitted))
                    Divider().padding(.leading, 52)
                    infoRow(icon: "building.2.fill", label: "Program", value: user.recoveryProgram)
                    Divider().padding(.leading, 52)
                    infoRow(icon: "calendar.badge.clock", label: "Discharge Date", value: user.dischargeDate.formatted(date: .abbreviated, time: .omitted))
                    Divider().padding(.leading, 52)
                    infoRow(icon: "clock.fill", label: "Days Since Admission", value: "\(viewModel.daysSinceAdmission) days")
                }
                .cardStyle()
                .padding(.horizontal)

                // My Posts
                if !viewModel.userPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Posts")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(viewModel.userPosts.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                        }
                        ForEach(viewModel.userPosts) { post in
                            PostCard(post: post)
                        }
                    }
                    .padding(.horizontal)
                }

                // Settings & Account
                VStack(spacing: 0) {
                    // Settings → full settings screen
                    NavigationLink {
                        SettingsScreen()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 28)
                            Text("Settings")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding()
                    }

                    Divider().padding(.leading, 52)

                    // Delete Account
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(AppTheme.struggling)
                                .frame(width: 28)
                            Text("Delete Account")
                                .foregroundStyle(AppTheme.struggling)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding()
                    }
                }
                .cardStyle()
                .padding(.horizontal)

                // Logout
                Button {
                    appViewModel.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(AppTheme.struggling)
                    .background(AppTheme.strugglingLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                appViewModel.deleteAccount()
            }
        } message: {
            Text("Your account will be deactivated for 30 days and then permanently deleted. Chat history will be retained per HIPAA requirements.")
        }
        .onAppear {
            viewModel.loadBadges()
            viewModel.loadUserPosts()
        }
    }

    private func legendRow(emoji: String, title: String, description: String, points: Int) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text("+\(points) pts")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
        }
        .padding()
    }

}
