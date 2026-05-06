import SwiftUI

// MARK: - SupportResourcesView

/// Emergency support resources sheet.
///
/// Shown automatically when `ContentSafetyEngine` detects:
/// - Any `high_risk` content (suicidal ideation, overdose intent, etc.)
/// - Any `isEmergency = true` result (user actively seeking help)
/// - Or at any risk level when the user taps "Need Help?" in the app
///
/// ## Design Principles
/// - NEVER blocks the user — this is an overlay, not a gate
/// - Always shows real, actionable resources
/// - One tap to call / text any resource
/// - Accessible, high-contrast design
struct SupportResourcesView: View {

    @Environment(\.dismiss) private var dismiss
    let triggerRiskLevel: ContentRiskLevel
    let showCrisisFirst: Bool

    init(
        riskLevel: ContentRiskLevel = .safe,
        showCrisisFirst: Bool = false
    ) {
        self.triggerRiskLevel = riskLevel
        self.showCrisisFirst  = showCrisisFirst
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    Divider()
                    resourcesList
                    footerNote
                }
            }
            .navigationTitle("Support Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    @ViewBuilder private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accent)

            Text("You are not alone.")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            Text("Immediate, free, and confidential support is available 24/7.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }

    // MARK: - Resources List

    private var resourcesList: some View {
        VStack(spacing: 12) {
            // Crisis resources listed with highest priority first
            ResourceCard(resource: .suicideCrisisLifeline,  isPrimary: showCrisisFirst)
            ResourceCard(resource: .crisisTextLine,          isPrimary: false)
            ResourceCard(resource: .samhsaHelpline,          isPrimary: false)
            ResourceCard(resource: .miltonSupportLine,       isPrimary: false)
            ResourceCard(resource: .emergency911,            isPrimary: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var footerNote: some View {
        Text("If you or someone else is in immediate danger, call 911.")
            .font(.footnote)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
    }
}

// MARK: - Resource Card

private struct ResourceCard: View {

    let resource: SupportResource
    let isPrimary: Bool

    @State private var showConfirmCall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: resource.icon)
                    .font(.title3)
                    .foregroundStyle(isPrimary ? .white : AppTheme.accent)
                    .frame(width: 40, height: 40)
                    .background(isPrimary ? AppTheme.accent : AppTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(resource.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(resource.availability)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            if let description = resource.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Action buttons (call / text)
            HStack(spacing: 8) {
                ForEach(resource.actions, id: \.label) { action in
                    Button {
                        openAction(action)
                    } label: {
                        Label(action.label, systemImage: action.icon)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isPrimary && action == resource.actions.first
                                        ? AppTheme.accent
                                        : AppTheme.accent.opacity(0.12))
                            .foregroundStyle(isPrimary && action == resource.actions.first
                                            ? .white
                                            : AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(isPrimary
                    ? AppTheme.accent.opacity(0.08)
                    : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            isPrimary ? RoundedRectangle(cornerRadius: 14).stroke(AppTheme.accent, lineWidth: 1.5) : nil
        )
    }

    private func openAction(_ action: SupportResource.Action) {
        guard let url = URL(string: action.url),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Support Resource Data

struct SupportResource: Sendable {

    struct Action: Equatable, Sendable {
        let label: String
        let icon: String
        let url: String
    }

    let name: String
    let icon: String
    let availability: String
    let description: String?
    let actions: [Action]

    // MARK: - Known Resources

    /// 988 Suicide & Crisis Lifeline — US national standard
    static let suicideCrisisLifeline = SupportResource(
        name: "988 Suicide & Crisis Lifeline",
        icon: "phone.fill",
        availability: "24/7 · Free · Confidential",
        description: "Call or text 988 to reach a trained crisis counselor.",
        actions: [
            Action(label: "Call 988",  icon: "phone.fill",    url: "tel:988"),
            Action(label: "Text 988",  icon: "message.fill",  url: "sms:988"),
        ]
    )

    /// Crisis Text Line
    static let crisisTextLine = SupportResource(
        name: "Crisis Text Line",
        icon: "message.fill",
        availability: "24/7 · Text Only · Free",
        description: "Text HOME to 741741 to connect with a crisis counselor.",
        actions: [
            Action(label: "Text HOME to 741741", icon: "message.fill", url: "sms:741741?body=HOME"),
        ]
    )

    /// SAMHSA National Helpline
    static let samhsaHelpline = SupportResource(
        name: "SAMHSA Helpline",
        icon: "cross.case.fill",
        availability: "24/7 · Free · Confidential",
        description: "Substance use & mental health treatment referrals.",
        actions: [
            Action(label: "Call 1-800-662-4357", icon: "phone.fill", url: "tel:18006624357"),
        ]
    )

    /// Milton Recovery Centers support line
    static let miltonSupportLine = SupportResource(
        name: "Milton Recovery Centers",
        icon: "person.2.fill",
        availability: "24/7 · Alumni Support",
        description: "Reach your care team directly.",
        actions: [
            Action(label: "Call (844) 406-4325", icon: "phone.fill", url: "tel:18444064325"),
        ]
    )

    /// Emergency services
    static let emergency911 = SupportResource(
        name: "Emergency Services",
        icon: "staroflife.fill",
        availability: "Immediate danger only",
        description: "If you or someone else is in immediate physical danger.",
        actions: [
            Action(label: "Call 911", icon: "phone.fill", url: "tel:911"),
        ]
    )
}

// MARK: - SwiftUI Integration View Modifier

/// Attach to any view that accepts user text to automatically surface
/// support resources when high-risk content is detected.
///
/// Example:
/// ```swift
/// TextEditor(text: $postText)
///     .contentSafetyOverlay(userId: currentUser.id, feature: .communityPost)
/// ```
struct ContentSafetyOverlay: ViewModifier {

    @Binding var text: String
    let userId: UUID?
    let feature: ContentFeature

    @State private var showResources = false
    @State private var currentRisk: ContentRiskLevel = .safe
    @State private var debounceTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { _, newValue in
                // Debounce: analyze after 600ms of inactivity
                debounceTask?.cancel()
                debounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    let result = ContentFilterService.shared.analyzeLocal(newValue)
                    if result.riskLevel != .safe || result.isEmergency {
                        currentRisk = result.riskLevel
                        showResources = true
                        // Full escalation (async, server notification) runs separately
                        Task {
                            _ = await ContentFilterService.shared.analyzeAndEscalate(
                                newValue, userId: userId, feature: feature
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showResources) {
                SupportResourcesView(
                    riskLevel: currentRisk,
                    showCrisisFirst: currentRisk == .highRisk
                )
            }
    }
}

extension View {
    /// Wraps a text-input view with automatic content safety detection and
    /// support resource surfacing. Does NOT block submission.
    func contentSafetyOverlay(
        text: Binding<String>,
        userId: UUID? = nil,
        feature: ContentFeature = .unknown
    ) -> some View {
        modifier(ContentSafetyOverlay(text: text, userId: userId, feature: feature))
    }
}
