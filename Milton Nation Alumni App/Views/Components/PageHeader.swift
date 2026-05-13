import SwiftUI

/// Standard header used at the top of EVERY tab so the logo height + colour
/// gradient bar are identical across screens. Created during the Build 6 pass
/// after the user noticed each tab had a slightly different header.
///
/// Usage:
/// ```
/// VStack(spacing: 0) {
///     PageHeader()
///     // ...tab content here
/// }
/// ```
struct PageHeader: View {
    /// Optional content slotted into the trailing edge of the header
    /// (e.g. a "+" button on Community to create a new post).
    var trailing: AnyView? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                MiltonLogoView(size: .small)
                if let trailing {
                    HStack {
                        Spacer()
                        trailing
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)        // FIXED height so headers align across tabs
            .padding(.vertical, 8)
            .background(AppTheme.cardBackground)

            // Brand colour gradient bar — same one Home used to have, now
            // shown under the logo on EVERY tab.
            HStack(spacing: 0) {
                ForEach(0..<AppTheme.brandPalette.count, id: \.self) { i in
                    AppTheme.brandPalette[i]
                        .frame(height: 3)
                }
            }
        }
    }
}

extension PageHeader {
    /// Convenience initializer for headers with a trailing button or label.
    init<Trailing: View>(@ViewBuilder trailing: () -> Trailing) {
        self.trailing = AnyView(trailing())
    }
}
