import SwiftUI

/// In-app settings for notification preferences, privacy, and appearance.
struct SettingsScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @AppStorage("notifications_community") private var notifyCommunity = true
    @AppStorage("notifications_chat") private var notifyChat = true
    @AppStorage("notifications_meetings") private var notifyMeetings = true
    @AppStorage("notifications_milestones") private var notifyMilestones = true
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("privacy_hide_sobriety") private var hideSobrietyDate = false
    @AppStorage("privacy_hide_profile_photo") private var hideProfilePhoto = false

    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showDataExportSheet = false
    @State private var exportedDataURL: URL?
    @State private var isExportingData = false

    var body: some View {
        List {
            // MARK: - Notifications
            Section {
                Toggle("Community Posts", isOn: $notifyCommunity)
                    .onChange(of: notifyCommunity) { PushNotificationService.shared.syncPreferences() }
                Toggle("Chat Messages", isOn: $notifyChat)
                    .onChange(of: notifyChat) { PushNotificationService.shared.syncPreferences() }
                Toggle("Meeting Reminders", isOn: $notifyMeetings)
                    .onChange(of: notifyMeetings) { PushNotificationService.shared.syncPreferences() }
                Toggle("Milestones & Badges", isOn: $notifyMilestones)
                    .onChange(of: notifyMilestones) { PushNotificationService.shared.syncPreferences() }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("System Notification Settings")
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            } header: {
                Label("Notifications", systemImage: "bell.fill")
            }

            // MARK: - Appearance
            Section {
                Picker("Theme", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Label("Appearance", systemImage: "paintbrush.fill")
            } footer: {
                Text("Choose how the app looks. System follows your device setting.")
            }

            // MARK: - Privacy
            Section {
                Toggle("Hide Sobriety Date from Peers", isOn: $hideSobrietyDate)
                Toggle("Hide Profile Photo from Peers", isOn: $hideProfilePhoto)
            } header: {
                Label("Privacy", systemImage: "hand.raised.fill")
            } footer: {
                Text("These settings only affect what other alumni can see. Staff and admins can always view your full profile.")
            }

            // MARK: - Legal
            Section {
                legalLink("Terms of Service",    urlString: "https://miltonrecovery.com/app-terms-conditions/")
                legalLink("Privacy Policy",       urlString: "https://miltonrecovery.com/app-privacy-policy/")
                legalLink("Support",              urlString: "https://miltonrecovery.com/app-support/")
            } header: {
                Label("Legal", systemImage: "doc.text.fill")
            }

            // MARK: - Data & Cache
            Section {
                Button(role: .destructive) {
                    OfflineCacheService.shared.clearAll()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Offline Cache")
                    }
                }

                // Download My Data (HIPAA Right to Access)
                Button {
                    exportMyData()
                } label: {
                    HStack {
                        if isExportingData {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text("Download My Data")
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .disabled(isExportingData)
            } header: {
                Label("Data", systemImage: "externaldrive.fill")
            } footer: {
                Text("Clears cached meetings, contacts, and quotes. Data will be re-downloaded on next use. Download My Data exports your profile, posts, and account info as a JSON file.")
            }

            // MARK: - Account
            Section {
                Button(role: .destructive) {
                    showDeleteAccountAlert = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                        Text("Delete My Account")
                    }
                }
            } header: {
                Label("Account", systemImage: "person.circle.fill")
            } footer: {
                Text("Deleting your account begins a 30-day grace period. Your data will be permanently removed after 30 days. This action cannot be undone.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Continue") { showDeleteConfirmation = true }
            } message: {
                Text("This will start a 30-day deletion process. Download your data first if you want a copy.")
            }
            .alert("Permanently Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete My Account", role: .destructive) {
                    AuditLogger.shared.log(.accountDeletionRequested, userId: appViewModel.currentUser?.id)
                    appViewModel.deleteAccount()
                }
            } message: {
                Text("Your account, posts, and messages will be permanently deleted after 30 days. You will be logged out immediately.")
            }

            // MARK: - About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            } header: {
                Label("About", systemImage: "info.circle.fill")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.accent)
        .sheet(isPresented: $showDataExportSheet) {
            if let url = exportedDataURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func legalLink(_ title: String, urlString: String) -> some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack {
                    Text(title)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Data Export

    private func exportMyData() {
        guard let user = appViewModel.currentUser else { return }
        isExportingData = true

        Task {
            let exportDict: [String: Any] = [
                "exported_at": ISO8601DateFormatter().string(from: Date()),
                "profile": [
                    "id": user.id.uuidString,
                    "full_name": user.fullName,
                    "username": user.username,
                    "email": user.email,
                    "phone": user.phone,
                    "recovery_program": user.recoveryProgram,
                    "sobriety_date": user.sobrietyDate.formatted(date: .abbreviated, time: .omitted),
                    "discharge_date": user.dischargeDate.formatted(date: .abbreviated, time: .omitted),
                    "total_points": user.totalPoints,
                    "role": user.role.rawValue,
                    "status": user.status.rawValue
                ],
                "note": "To request a full copy of all messages and posts, contact support@miltonrecovery.com"
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted) {
                let fileName = "MiltonAlumni_MyData_\(Date().formatted(.iso8601)).json"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try jsonData.write(to: url)
                    AuditLogger.shared.log(.exportUserData, userId: user.id, detail: "User requested data export")
                    await MainActor.run {
                        exportedDataURL = url
                        isExportingData = false
                        showDataExportSheet = true
                    }
                } catch {
                    await MainActor.run { isExportingData = false }
                }
            } else {
                await MainActor.run { isExportingData = false }
            }
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
