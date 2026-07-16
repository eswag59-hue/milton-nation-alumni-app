import SwiftUI
import Supabase

@Observable
final class ProfileViewModel {
    var user: User
    var badges: [Badge] = []
    var earnedBadgeIds: Set<UUID> = []
    var showEditProfile = false
    var isLoading = false
    var isUploadingPhoto = false
    var photoUploadError: String?

    /// Called whenever this VM mutates the profile (photo upload, future edits).
    /// ProfileScreen wires this to `AppViewModel.refreshCurrentUser` so the
    /// rest of the app (Home counter, header avatar, chat sender info) sees
    /// the change immediately and the change survives navigating away + back.
    var onProfileUpdate: ((User) -> Void)?

    // MARK: - Task Cancellation
    private var badgeTask: Task<Void, Never>?
    private var postsTask: Task<Void, Never>?

    private let dataService: DataServiceProtocol

    init(user: User, dataService: DataServiceProtocol = DefaultServices.dataService) {
        self.user = user
        self.dataService = dataService
    }

    func loadBadges() {
        badgeTask?.cancel()
        badgeTask = Task {
            let fetchedBadges = (try? await dataService.fetchBadges()) ?? []
            let userBadges = (try? await dataService.fetchUserBadges()) ?? []
            guard !Task.isCancelled else { return }
            await MainActor.run {
                badges = fetchedBadges
                earnedBadgeIds = Set(userBadges.map(\.badgeId))
            }
        }
    }

    var userPosts: [CommunityPost] = []

    func loadUserPosts() {
        postsTask?.cancel()
        postsTask = Task {
            let allPosts = (try? await dataService.fetchPosts(category: nil)) ?? []
            guard !Task.isCancelled else { return }
            await MainActor.run {
                userPosts = allPosts.filter { $0.userId == user.id }
            }
        }
    }

    // MARK: - Profile Photo Upload

    /// Upload profile photo data to Supabase Storage and update user profile.
    func uploadProfilePhoto(imageData: Data) {
        Task {
            await MainActor.run {
                isUploadingPhoto = true
                photoUploadError = nil
            }

            do {
                var photoURL: String

                if SupabaseConfig.isConfigured {
                    // Upload to Supabase Storage.
                    // CRITICAL: the storage RLS policy on `profile-photos` requires
                    // `(storage.foldername(name))[1] = auth.uid()::text`, meaning
                    // the FIRST folder in the path must be the user's UUID.
                    // Prefixing with "profiles/" makes the first folder literally
                    // "profiles" → policy fails → upload returns "Failed to upload
                    // photo." Path must be `{user.id}/avatar.jpg` only.
                    // Path folder MUST be the LOWERCASE uuid: the storage RLS
                    // policy compares (foldername)[1] to auth.uid()::text, which
                    // is lowercase. Swift's uuidString is UPPERCASE, so an
                    // uppercase folder fails the policy → "Failed to upload photo".
                    let storagePath = "\(user.id.uuidString.lowercased())/avatar.jpg"

                    // Compress image for upload
                    let compressedData: Data
                    if let uiImage = UIImage(data: imageData),
                       let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                        compressedData = compressed
                    } else {
                        compressedData = imageData
                    }

                    try await SupabaseConfig.client.storage
                        .from("profile-photos")
                        .upload(storagePath, data: compressedData, options: .init(upsert: true))

                    let publicURL = try SupabaseConfig.client.storage
                        .from("profile-photos")
                        .getPublicURL(path: storagePath)

                    photoURL = publicURL.absoluteString
                } else {
                    // Mock: generate a fake URL
                    photoURL = "mock://profile/\(user.id.uuidString)/avatar.jpg"
                }

                // Update user profile with new photo URL
                var updatedUser = user
                updatedUser.profilePhotoURL = photoURL
                let saved = try await dataService.updateProfile(user: updatedUser)

                await MainActor.run {
                    user = saved
                    isUploadingPhoto = false
                    photoUploadError = nil   // clear any previous error on success
                    // Sync the new profile back to AppViewModel so other screens
                    // (Home avatar, chat sender info, struggling modal) pick up
                    // the change and so the change SURVIVES navigating away + back.
                    onProfileUpdate?(saved)
                }
            } catch {
                CrashReportingService.shared.recordError(error, context: "ProfileViewModel.uploadProfilePhoto")
                await MainActor.run {
                    photoUploadError = "Failed to upload photo. Please try again."
                    isUploadingPhoto = false
                }
            }
        }
    }

    // MARK: - Computed Properties

    var daysSinceAdmission: Int {
        Calendar.current.dateComponents([.day], from: user.dischargeDate, to: Date()).day ?? 0
    }

    var nextBadge: Badge? {
        badges.sorted(by: { $0.pointsRequired < $1.pointsRequired })
            .first(where: { $0.pointsRequired > user.totalPoints })
    }

    var progressToNextBadge: Double {
        guard let next = nextBadge else { return 1.0 }
        let previousThreshold = badges
            .sorted(by: { $0.pointsRequired < $1.pointsRequired })
            .last(where: { $0.pointsRequired <= user.totalPoints })?.pointsRequired ?? 0
        let range = Double(next.pointsRequired - previousThreshold)
        guard range > 0 else { return 0 }
        return Double(user.totalPoints - previousThreshold) / range
    }

    // MARK: - Cleanup

    func cancelTasks() {
        badgeTask?.cancel()
        postsTask?.cancel()
        badgeTask = nil
        postsTask = nil
    }
}
