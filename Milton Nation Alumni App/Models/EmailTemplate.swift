import Foundation

struct EmailTemplate: Identifiable, Codable {
    let id: UUID
    var templateType: TemplateType
    var subject: String
    var bodyHTML: String

    enum TemplateType: String, Codable {
        case welcome
        case passwordReset
        case sobrietyMilestone
        case twoFactorCode
        case accountActivated
        case accountDeactivated

        var displayName: String {
            switch self {
            case .welcome: return "Welcome"
            case .passwordReset: return "Password Reset"
            case .sobrietyMilestone: return "Sobriety Milestone"
            case .twoFactorCode: return "Two-Factor Code"
            case .accountActivated: return "Account Activated"
            case .accountDeactivated: return "Account Deactivated"
            }
        }
    }
}
