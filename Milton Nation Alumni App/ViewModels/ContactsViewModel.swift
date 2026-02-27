import SwiftUI

@Observable
final class ContactsViewModel {
    var crisisResources: [CrisisResource] = MockData.crisisResources
    var companyContacts: [CompanyContact] = MockData.companyContacts
    var sponsorName: String = ""
    var sponsorPhone: String = ""
    var isEditingSponsor = false

    func callNumber(_ number: String) {
        PhoneService.call(number)
    }

    func saveSponsor() {
        isEditingSponsor = false
    }
}
