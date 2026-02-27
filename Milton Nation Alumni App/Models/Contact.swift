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
