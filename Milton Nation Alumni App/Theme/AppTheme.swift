import SwiftUI

enum AppTheme {
    // MARK: - Brand Colors (exact Milton Recovery Centers palette)
    static let primary = Color(hex: "101820")         // Black 6 C (1st swatch)
    static let primaryMedium = Color(hex: "165C7D")    // 7700 C (2nd swatch)
    static let accent = Color(hex: "007396")           // 633 C (3rd swatch)
    static let accentMedium = Color(hex: "0093B2")     // 632 C (4th swatch)
    static let accentLight = Color(hex: "369DA0")      // 6137 C (5th swatch)
    static let accentSage = Color(hex: "56B093")       // 2459 C (6th swatch)
    static let accentLime = Color(hex: "D4EB8E")       // 372 C (7th swatch)

    // MARK: - Brand Palette Array (for swatches display)
    static let brandPalette: [Color] = [
        primary, primaryMedium, accent, accentMedium, accentLight, accentSage, accentLime
    ]

    // MARK: - Semantic Colors (adaptive for dark mode)
    static let background = Color("AppBackground", bundle: nil)
    static let cardBackground = Color("CardBackground", bundle: nil)
    static let struggling = Color(hex: "E74C3C")
    static let strugglingLight = Color("StrugglingLight", bundle: nil)
    static let textPrimary = Color("TextPrimary", bundle: nil)
    static let textSecondary = Color("TextSecondary", bundle: nil)
    static let textOnPrimary = Color.white
    static let divider = Color("AppDivider", bundle: nil)

    // MARK: - Dark-adaptive surface for detail sheets (teal tinted, not pure black)
    static let sheetBackground = Color("SheetBackground", bundle: nil)

    // MARK: - Fallback Semantic Colors (used when asset catalog colors aren't available)
    static let backgroundLight = Color(hex: "F2F5F5")
    static let cardBackgroundLight = Color.white
    static let textPrimaryLight = Color(hex: "101820")
    static let textSecondaryLight = Color(hex: "6B7280")
    static let dividerLight = Color(hex: "E0E5E5")

    // Category colors (tied to brand palette)
    static let winsColor = Color(hex: "56B093")        // Sage green
    static let strugglesColor = Color(hex: "E8A838")
    static let supportColor = Color(hex: "0093B2")     // Medium teal
    static let gratitudeColor = Color(hex: "D4EB8E")   // Lime accent
    static let generalColor = Color(hex: "6B7280")

    // MARK: - Gradients
    static let headerGradient = LinearGradient(
        colors: [primary, primaryMedium],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sobrietyGradient = LinearGradient(
        colors: [accentMedium.opacity(0.15), accentLight.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        colors: brandPalette,
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10

    // MARK: - Card Style
    static func cardStyle() -> some ViewModifier {
        CardModifier()
    }

}

// MARK: - Reusable Brand Logo View
struct MiltonLogoView: View {
    enum LogoSize {
        case small, medium, large, extraLarge
    }

    var size: LogoSize = .large

    private var logoHeight: CGFloat {
        switch size {
        case .small: return 55
        case .medium: return 70
        case .large: return 140
        case .extraLarge: return 180
        }
    }

    var body: some View {
        Image("MiltonLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: logoHeight)
            .accessibilityLabel("Milton Alumni logo")
    }
}

// Helper to erase type for conditional backgrounds
extension View {
    func asAnyView() -> AnyView { AnyView(self) }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
