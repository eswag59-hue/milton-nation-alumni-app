import Foundation

enum CrisisContactType: String {
    case phone
    case sms
}

struct CrisisResource: Identifiable {
    let id = UUID()
    var name: String
    var phoneNumber: String
    var description: String?
    var isEmergency: Bool
    var contactType: CrisisContactType = .phone
}

struct CompanyContact: Identifiable {
    let id = UUID()
    var name: String
    var phoneNumber: String
    var role: String?
}

struct Sponsor: Codable {
    var name: String
    var phoneNumber: String
}

// MARK: - App Contacts (production config, NOT mock data)

/// Fixed crisis hotlines and Milton support numbers shown across the app
/// (Struggling modal, Contacts screen, Admin contact manager). These are real,
/// nationally-published crisis resources and Milton's real support line — they
/// are app configuration, not fabricated patient data, and are intentionally
/// hardcoded so they work with zero network and can never be empty in a crisis.
///
/// If these ever need to be facility-specific or admin-editable, back them with
/// a Supabase table; until then this is the single source of truth (previously
/// duplicated in `MockData`).
enum AppContacts {
    static let crisisResources: [CrisisResource] = [
        CrisisResource(name: "988 Suicide & Crisis Lifeline", phoneNumber: "988", description: "24/7 crisis support", isEmergency: true),
        CrisisResource(name: "SAMHSA Helpline", phoneNumber: "1-800-662-4357", description: "Free, confidential, 24/7 treatment referral", isEmergency: true),
        CrisisResource(name: "Crisis Text Line", phoneNumber: "741741", description: "Text HOME to 741741", isEmergency: true, contactType: .sms),
    ]

    static let companyContacts: [CompanyContact] = [
        CompanyContact(name: "Milton Team", phoneNumber: "(844) 406-4325", role: "General Inquiries"),
        CompanyContact(name: "After-Hours Support", phoneNumber: "(844) 406-4325", role: "24/7 Support Line"),
    ]
}
