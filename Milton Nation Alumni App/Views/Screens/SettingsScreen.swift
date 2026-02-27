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

    var body: some View {
        List {
            // MARK: - Notifications
            Section {
                Toggle("Community Posts", isOn: $notifyCommunity)
                Toggle("Chat Messages", isOn: $notifyChat)
                Toggle("Meeting Reminders", isOn: $notifyMeetings)
                Toggle("Milestones & Badges", isOn: $notifyMilestones)

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
                Link(destination: URL(string: "https://miltonrecovery.com/terms")!) {
                    HStack {
                        Text("Terms of Service")
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Link(destination: URL(string: "https://miltonrecovery.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
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
            } header: {
                Label("Data", systemImage: "externaldrive.fill")
            } footer: {
                Text("Clears cached meetings, contacts, and quotes. Data will be re-downloaded on next use.")
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
    }
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
