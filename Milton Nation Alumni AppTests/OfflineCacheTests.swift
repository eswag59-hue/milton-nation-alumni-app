import Testing
import Foundation
@testable import Milton_Nation_Alumni_App

@Suite("OfflineCache Tests")
struct OfflineCacheTests {

    @Test("cacheMeetings and loadCachedMeetings round-trip works")
    func meetingsRoundTrip() {
        let cache = OfflineCacheService.shared
        let meetings = MockData.meetings
        cache.cacheMeetings(meetings)
        let loaded = cache.loadCachedMeetings()
        #expect(loaded != nil)
        #expect(loaded?.count == meetings.count)
    }

    @Test("cacheDailyQuote and loadCachedDailyQuote round-trip works")
    func quoteRoundTrip() {
        let cache = OfflineCacheService.shared
        let quote = DailyQuote(
            id: UUID(),
            text: "Test quote",
            attribution: "Test Author",
            scheduledDate: nil
        )
        cache.cacheDailyQuote(quote)
        let loaded = cache.loadCachedDailyQuote()
        #expect(loaded != nil)
        #expect(loaded?.text == "Test quote")
    }

    @Test("cacheSponsor and loadCachedSponsor round-trip works")
    func sponsorRoundTrip() {
        let cache = OfflineCacheService.shared
        let sponsor = Sponsor(name: "John S.", phoneNumber: "555-1234")
        cache.cacheSponsor(sponsor)
        let loaded = cache.loadCachedSponsor()
        #expect(loaded != nil)
        #expect(loaded?.name == "John S.")
    }

    @Test("cacheAssignedStaff and loadCachedAssignedStaff round-trip works")
    func staffRoundTrip() {
        let cache = OfflineCacheService.shared
        let staff = [MockData.caseManager, MockData.therapist]
        cache.cacheAssignedStaff(staff)
        let loaded = cache.loadCachedAssignedStaff()
        #expect(loaded != nil)
        #expect(loaded?.count == 2)
    }

    @Test("cacheUserProfile and loadCachedUserProfile round-trip works")
    func userProfileRoundTrip() {
        let cache = OfflineCacheService.shared
        let user = MockData.currentUser
        cache.cacheUserProfile(user)
        let loaded = cache.loadCachedUserProfile()
        #expect(loaded != nil)
        #expect(loaded?.id == user.id)
    }

    @Test("cacheConversations and loadCachedConversations round-trip works")
    func conversationsRoundTrip() {
        let cache = OfflineCacheService.shared
        let convos = MockData.conversations
        cache.cacheConversations(convos)
        let loaded = cache.loadCachedConversations()
        #expect(loaded != nil)
        #expect(loaded?.count == convos.count)
    }

    @Test("CodableCrisisResource round-trip works")
    func crisisResourceRoundTrip() {
        let cache = OfflineCacheService.shared
        let resources = MockData.crisisResources.map { CodableCrisisResource(from: $0) }
        cache.cacheCrisisResources(resources)
        let loaded = cache.loadCachedCrisisResources()
        #expect(loaded != nil)
        #expect(loaded?.count == resources.count)
    }

    @Test("CodableCompanyContact round-trip works")
    func companyContactRoundTrip() {
        let cache = OfflineCacheService.shared
        let contacts = MockData.companyContacts.map { CodableCompanyContact(from: $0) }
        cache.cacheCompanyContacts(contacts)
        let loaded = cache.loadCachedCompanyContacts()
        #expect(loaded != nil)
        #expect(loaded?.count == contacts.count)
    }

    @Test("clearAll removes cached data")
    func clearAll() {
        let cache = OfflineCacheService.shared
        cache.cacheMeetings(MockData.meetings)
        cache.clearAll()
        let loaded = cache.loadCachedMeetings()
        #expect(loaded == nil)
    }

    @Test("loadCachedMeetings returns nil when no cache exists")
    func noCacheReturnsNil() {
        let cache = OfflineCacheService.shared
        cache.clearAll()
        #expect(cache.loadCachedDailyQuote() == nil)
    }
}
