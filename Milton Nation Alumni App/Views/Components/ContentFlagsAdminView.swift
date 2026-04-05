import SwiftUI

// MARK: - ContentFlagsAdminView

/// Admin panel section showing flagged content from the content safety engine.
/// Displays all flags (all risk levels) with filtering, review, and dismiss actions.
/// HIPAA-safe: only shows redacted summaries — no raw user text.
struct ContentFlagsAdminView: View {

    @Bindable var viewModel: AdminViewModel
    @State private var selectedFlag: ContentFlag? = nil
    @State private var showReviewSheet = false
    @State private var reviewNote = ""

    // MARK: - Filtered Flags

    private var filteredFlags: [ContentFlag] {
        guard let filter = viewModel.contentFlagFilterStatus else {
            return viewModel.contentFlags
        }
        return viewModel.contentFlags.filter { $0.reviewStatus == filter }
    }

    private var emergencyFlags: [ContentFlag] {
        filteredFlags.filter { $0.isEmergency }
    }

    private var regularFlags: [ContentFlag] {
        filteredFlags.filter { !$0.isEmergency }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            filterBar
            content
        }
        .padding()
        .cardStyle()
        .padding(.horizontal)
        .sheet(item: $selectedFlag) { flag in
            reviewSheet(for: flag)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundStyle(AppTheme.struggling)
            Text("Content Safety Flags")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if viewModel.pendingFlagCount > 0 {
                Text("\(viewModel.pendingFlagCount) pending")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.struggling.opacity(0.15))
                    .foregroundStyle(AppTheme.struggling)
                    .clipShape(Capsule())
            }
            if viewModel.isLoadingContentFlags {
                ProgressView()
                    .controlSize(.mini)
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", status: nil)
                filterChip(label: "Pending", status: .pending)
                filterChip(label: "Escalated", status: .escalated)
                filterChip(label: "Reviewed", status: .reviewed)
                filterChip(label: "Dismissed", status: .dismissed)
            }
        }
    }

    private func filterChip(label: String, status: ContentFlag.ReviewStatus?) -> some View {
        let isSelected = viewModel.contentFlagFilterStatus == status
        return Button {
            viewModel.contentFlagFilterStatus = status
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.accent : AppTheme.background)
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.contentFlags.isEmpty && !viewModel.isLoadingContentFlags {
            emptyState
        } else if filteredFlags.isEmpty {
            Text("No flags match this filter.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 8) {
                // Emergency flags always shown first
                if !emergencyFlags.isEmpty {
                    emergencyBanner
                    ForEach(emergencyFlags) { flag in
                        flagRow(flag)
                    }
                    if !regularFlags.isEmpty {
                        Divider()
                    }
                }
                ForEach(regularFlags) { flag in
                    flagRow(flag)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(AppTheme.accentSage)
            Text("No content flags on record.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }

    private var emergencyBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .font(.caption)
            Text("EMERGENCY FLAGS — User may need immediate help")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.struggling)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Flag Row

    private func flagRow(_ flag: ContentFlag) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top row: risk pill + emergency indicator + timestamp
            HStack(spacing: 6) {
                riskBadge(for: flag.riskLevel)
                if flag.isEmergency {
                    Label("Emergency", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.struggling)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(flag.formattedTimestamp)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                statusBadge(for: flag.reviewStatus)
            }

            // Categories
            if !flag.categories.isEmpty {
                HStack(spacing: 4) {
                    ForEach(flag.categories, id: \.self) { category in
                        Text(categoryLabel(category))
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.accent.opacity(0.12))
                            .foregroundStyle(AppTheme.accent)
                            .clipShape(Capsule())
                    }
                    Text(flag.feature.displayName)
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            // Redacted summary (HIPAA-safe — no raw user text)
            Text(flag.redactedSummary)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            // Action buttons (only for actionable statuses)
            if flag.reviewStatus == .pending || flag.reviewStatus == .escalated {
                HStack(spacing: 8) {
                    Button {
                        selectedFlag = flag
                    } label: {
                        Label("Review", systemImage: "checkmark.circle")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(AppTheme.accentSage.opacity(0.15))
                            .foregroundStyle(AppTheme.accentSage)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button {
                        viewModel.dismissFlag(flag)
                    } label: {
                        Label("Dismiss", systemImage: "xmark.circle")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(AppTheme.textSecondary.opacity(0.1))
                            .foregroundStyle(AppTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    if flag.reviewStatus != .escalated {
                        Button {
                            viewModel.escalateFlag(flag)
                        } label: {
                            Label("Escalate", systemImage: "arrow.up.circle")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(AppTheme.struggling.opacity(0.12))
                                .foregroundStyle(AppTheme.struggling)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }

            // Review note (if any)
            if let note = flag.reviewNote, !note.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                    Text(note)
                        .font(.caption2)
                }
                .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(12)
        .background(flag.isEmergency
                    ? AppTheme.struggling.opacity(0.06)
                    : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            flag.isEmergency
                ? RoundedRectangle(cornerRadius: 10).stroke(AppTheme.struggling.opacity(0.3), lineWidth: 1)
                : nil
        )
    }

    // MARK: - Review Sheet

    @ViewBuilder
    private func reviewSheet(for flag: ContentFlag) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Flag summary
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        riskBadge(for: flag.riskLevel)
                        if flag.isEmergency {
                            Label("Emergency", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.struggling)
                        }
                        Spacer()
                        Text(flag.formattedTimestamp)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Text("Categories: \(flag.categories.map { categoryLabel($0) }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Feature: \(flag.feature.displayName)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(flag.redactedSummary)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Review note
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review Note (optional)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    TextEditor(text: $reviewNote)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.divider))
                }

                Spacer()

                // Action buttons
                VStack(spacing: 10) {
                    Button {
                        viewModel.reviewFlag(flag, note: reviewNote.isEmpty ? nil : reviewNote)
                        selectedFlag = nil
                        reviewNote = ""
                    } label: {
                        Label("Mark Reviewed", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accentSage)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }

                    Button {
                        viewModel.escalateFlag(flag, note: reviewNote.isEmpty ? nil : reviewNote)
                        selectedFlag = nil
                        reviewNote = ""
                    } label: {
                        Label("Escalate to Support Team", systemImage: "arrow.up.circle.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.struggling.opacity(0.15))
                            .foregroundStyle(AppTheme.struggling)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                }
            }
            .padding()
            .navigationTitle("Review Flag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedFlag = nil
                        reviewNote = ""
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func riskBadge(for level: ContentRiskLevel) -> some View {
        let (label, color): (String, Color) = switch level {
        case .safe:       ("Safe",    AppTheme.accentSage)
        case .lowRisk:    ("Low",     AppTheme.accentLime)
        case .mediumRisk: ("Medium",  .orange)
        case .highRisk:   ("High",    AppTheme.struggling)
        }
        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statusBadge(for status: ContentFlag.ReviewStatus) -> some View {
        let (label, color): (String, Color) = switch status {
        case .pending:   ("Pending",   .orange)
        case .reviewed:  ("Reviewed",  AppTheme.accentSage)
        case .dismissed: ("Dismissed", AppTheme.textSecondary)
        case .escalated: ("Escalated", AppTheme.struggling)
        }
        return Text(label)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func categoryLabel(_ category: ContentCategory) -> String {
        switch category {
        case .selfHarm:  return "Self-Harm"
        case .drugs:     return "Drugs"
        case .alcohol:   return "Alcohol"
        case .violence:  return "Violence"
        }
    }
}
