import SwiftUI

@Observable
final class ContactsViewModel {
    var crisisResources: [CrisisResource] = MockData.crisisResources
    var companyContacts: [CompanyContact] = MockData.companyContacts
    var sponsorName: String = ""
    var sponsorPhone: String = ""
    var isEditingSponsor = false

    private let sponsorNameKey  = "sponsor_name"
    private let sponsorPhoneKey = "sponsor_phone"

    init() {
        // Restore persisted sponsor — survives app relaunch
        sponsorName  = UserDefaults.standard.string(forKey: sponsorNameKey)  ?? ""
        sponsorPhone = UserDefaults.standard.string(forKey: sponsorPhoneKey) ?? ""
    }

    func callNumber(_ number: String) {
        PhoneService.call(number)
    }

    func saveSponsor() {
        // Persist sponsor to UserDefaults so it survives relaunch
        UserDefaults.standard.set(sponsorName,  forKey: sponsorNameKey)
        UserDefaults.standard.set(sponsorPhone, forKey: sponsorPhoneKey)
        isEditingSponsor = false
    }
}
