import Foundation

/// Persistent offline cache for critical data that must be available without network.
///
/// Caches:
/// - Crisis contacts (always available for safety)
/// - Company contacts
/// - Care team / assigned staff
/// - Recent meetings
/// - Sponsor info
/// - Daily quote (last fetched)
///
/// Uses FileManager for JSON persistence to the app's caches directory.
/// Data is written on every successful fetch and read as fallback when
/// network requests fail.
final class OfflineCacheService: Sendable {

    static let shared = OfflineCacheService()

    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("OfflineCache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
        }
        return dir
    }

    private init() {}

    // MARK: - Cache Keys

    private enum CacheKey: String {
        case crisisResources = "crisis_resources"
        case companyContacts = "company_contacts"
        case assignedStaff = "assigned_staff"
        case meetings = "meetings"
        case sponsor = "sponsor"
        case dailyQuote = "daily_quote"
        case conversations = "conversations"
        case userProfile = "user_profile"
    }

    // MARK: - Generic Read/Write

    private func write<T: Encodable>(_ value: T, for key: CacheKey) {
        let url = cacheDirectory.appendingPathComponent("\(key.rawValue).json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        // HIPAA: protect cached PHI from lock-screen access
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
        } catch {
            #if DEBUG
            print("[OfflineCache] ⚠️ Failed to write \(key.rawValue): \(error.localizedDescription)")
            #endif
        }
    }

    private func read<T: Decodable>(_ type: T.Type, for key: CacheKey) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key.rawValue).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print("[OfflineCache] ⚠️ Failed to read \(key.rawValue): \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    // MARK: - Crisis Resources

    func cacheCrisisResources(_ resources: [CodableCrisisResource]) {
        write(resources, for: .crisisResources)
    }

    func loadCachedCrisisResources() -> [CodableCrisisResource]? {
        read([CodableCrisisResource].self, for: .crisisResources)
    }

    // MARK: - Company Contacts

    func cacheCompanyContacts(_ contacts: [CodableCompanyContact]) {
        write(contacts, for: .companyContacts)
    }

    func loadCachedCompanyContacts() -> [CodableCompanyContact]? {
        read([CodableCompanyContact].self, for: .companyContacts)
    }

    // MARK: - Assigned Staff (Care Team)

    func cacheAssignedStaff(_ staff: [User]) {
        write(staff, for: .assignedStaff)
    }

    func loadCachedAssignedStaff() -> [User]? {
        read([User].self, for: .assignedStaff)
    }

    // MARK: - Meetings

    func cacheMeetings(_ meetings: [Meeting]) {
        write(meetings, for: .meetings)
    }

    func loadCachedMeetings() -> [Meeting]? {
        read([Meeting].self, for: .meetings)
    }

    // MARK: - Sponsor

    func cacheSponsor(_ sponsor: Sponsor) {
        write(sponsor, for: .sponsor)
    }

    func loadCachedSponsor() -> Sponsor? {
        read(Sponsor.self, for: .sponsor)
    }

    // MARK: - Daily Quote

    func cacheDailyQuote(_ quote: DailyQuote) {
        write(quote, for: .dailyQuote)
    }

    func loadCachedDailyQuote() -> DailyQuote? {
        read(DailyQuote.self, for: .dailyQuote)
    }

    // MARK: - Conversations

    func cacheConversations(_ conversations: [Conversation]) {
        write(conversations, for: .conversations)
    }

    func loadCachedConversations() -> [Conversation]? {
        read([Conversation].self, for: .conversations)
    }

    // MARK: - User Profile

    func cacheUserProfile(_ user: User) {
        write(user, for: .userProfile)
    }

    func loadCachedUserProfile() -> User? {
        read(User.self, for: .userProfile)
    }

    // MARK: - Clear All

    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }

    // MARK: - Cache Age Check

    func cacheAge(for key: String) -> TimeInterval? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let modDate = attributes[.modificationDate] as? Date else { return nil }
        return Date().timeIntervalSince(modDate)
    }
}

// MARK: - Codable Wrappers for Non-Codable Models

/// Codable version of CrisisResource for offline caching.
nonisolated struct CodableCrisisResource: Codable, Sendable {
    let name: String
    let phoneNumber: String
    let description: String?
    let isEmergency: Bool
    let contactType: String

    init(from resource: CrisisResource) {
        self.name = resource.name
        self.phoneNumber = resource.phoneNumber
        self.description = resource.description
        self.isEmergency = resource.isEmergency
        self.contactType = resource.contactType.rawValue
    }

    func toCrisisResource() -> CrisisResource {
        CrisisResource(
            name: name,
            phoneNumber: phoneNumber,
            description: description,
            isEmergency: isEmergency,
            contactType: CrisisContactType(rawValue: contactType) ?? .phone
        )
    }
}

/// Codable version of CompanyContact for offline caching.
nonisolated struct CodableCompanyContact: Codable, Sendable {
    let name: String
    let phoneNumber: String
    let role: String?

    init(from contact: CompanyContact) {
        self.name = contact.name
        self.phoneNumber = contact.phoneNumber
        self.role = contact.role
    }

    func toCompanyContact() -> CompanyContact {
        CompanyContact(name: name, phoneNumber: phoneNumber, role: role)
    }
}
