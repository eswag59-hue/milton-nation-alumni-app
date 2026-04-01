import SwiftUI

/// Shown to super admins immediately after login, and accessible via "Switch Facility" in the admin dashboard.
/// Lets the super admin choose which facility's data to manage.
struct FacilityPickerScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.accent)
                    Text("Select Facility")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Which facility would you like to manage?")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 24)

                // Facility cards
                VStack(spacing: 16) {
                    ForEach(Facility.allCases) { facility in
                        facilityCard(facility)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Current selection indicator (if already selected)
                if !appViewModel.showFacilityPicker {
                    Text("Currently viewing: \(appViewModel.activeFacility.emoji) \(appViewModel.activeFacility.displayName)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.bottom, 24)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Only show dismiss if this is a re-open (already have an active facility)
                if !appViewModel.showFacilityPicker {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
        }
    }

    private func facilityCard(_ facility: Facility) -> some View {
        let isActive = appViewModel.activeFacility == facility

        return Button {
            appViewModel.selectFacility(facility)
            dismiss()
        } label: {
            HStack(spacing: 16) {
                Text(facility.emoji)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 4) {
                    Text(facility.displayName)
                        .font(.headline)
                        .foregroundStyle(isActive ? .white : AppTheme.textPrimary)
                    Text("Milton Recovery \(facility.displayName)")
                        .font(.caption)
                        .foregroundStyle(isActive ? .white.opacity(0.8) : AppTheme.textSecondary)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(isActive ? AppTheme.accent : AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(isActive ? AppTheme.accent : AppTheme.divider, lineWidth: isActive ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
