import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    /// The user passed in at view-creation. Used as a seed; the body always
    /// reads `appViewModel.currentUser` so updates (sobriety reset, points,
    /// approval status) propagate live.
    let user: User
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel: ProfileViewModel
    /// Dedicated CommunityViewModel for the MyPostsList navigation chain.
    /// We don't reuse CommunityScreen's VM because that lives inside its own
    /// NavigationStack — making one here keeps post mutations (edit / delete /
    /// like-comment) self-contained to this navigation hierarchy.
    @State private var communityVMForList = CommunityViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showEditProfile = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: Image?

    /// Live user — falls back to the init-time `user` if AppViewModel hasn't
    /// hydrated yet (e.g. previews). Avoids the "ProfileScreen shows stale
    /// sobriety date until logout/login" bug.
    private var liveUser: User {
        appViewModel.currentUser ?? user
    }

    init(user: User) {
        self.user = user
        self._viewModel = State(initialValue: ProfileViewModel(user: user))
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader()

            ScrollView {
                VStack(spacing: 20) {
                    Color.clear.frame(height: 12)  // Lower the profile-photo area slightly

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
                            } else if let urlString = liveUser.profilePhotoURL,
                                      let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(AppTheme.accent.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                            .overlay {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 36))
                                                    .foregroundStyle(AppTheme.accent)
                                            }
                                    }
                                }
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
                    Text(liveUser.fullName)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("@\(liveUser.username)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                    Text(liveUser.email)
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

                    // Badges grid — 4 columns so each badge gets enough room.
                    // Previous 6-column grid caused emoji/text to clip on
                    // narrow iPhones because each cell was ~60pt wide.
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ], spacing: 14) {
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
                    infoRow(icon: "clock.fill", label: "Days Since Discharge", value: "\(viewModel.daysSinceAdmission) days")
                }
                .cardStyle()
                .padding(.horizontal)

                // My Posts → tap to navigate to a dedicated list. Per user
                // feedback in TestFlight, showing all posts inline on the
                // profile screen pushed everything else off the bottom; this
                // collapses the section to a single row + count.
                if !viewModel.userPosts.isEmpty {
                    NavigationLink {
                        MyPostsListScreen(communityVM: communityVMForList)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.text.square.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 28)
                            Text("My Posts")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(viewModel.userPosts.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding()
                    }
                    .cardStyle()
                    .padding(.horizontal)
                }

                // Settings & Account
                VStack(spacing: 0) {
                    // Edit profile → name + verified phone change
                    Button {
                        showEditProfile = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.text.rectangle.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 28)
                            Text("Edit Profile")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }

                    Divider().padding(.leading, 56)

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
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: liveUser)
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                AuditLogger.shared.log(.accountDeletionRequested, userId: appViewModel.currentUser?.id)
                appViewModel.deleteAccount()
            }
        } message: {
            Text("This starts a 30-day grace period, after which your personal data — profile, posts, comments, and messages — is permanently removed. Records we're clinically or legally required to keep are retained per HIPAA. You'll be logged out now.")
        }
        .onAppear {
            viewModel.loadBadges()
            viewModel.loadUserPosts()
            // Wire the ProfileViewModel's update hook to the shared AppViewModel
            // so the new photo URL (and any future profile edits) propagates to
            // the Home counter, header avatar, etc. — and survives navigation.
            viewModel.onProfileUpdate = { updatedUser in
                appViewModel.refreshCurrentUser(updatedUser)
            }
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
