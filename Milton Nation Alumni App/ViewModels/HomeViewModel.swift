import SwiftUI

@Observable
final class HomeViewModel {
    var dailyQuote: DailyQuote?
    var announcements: [Announcement] = []
    var showStrugglingModal = false
    var isLoading = false
    var errorMessage: String?

    // MARK: - Task Cancellation
    private var loadTask: Task<Void, Never>?

    private let dataService: DataServiceProtocol
    private let cache = OfflineCacheService.shared

    init(dataService: DataServiceProtocol = MockDataService()) {
        self.dataService = dataService
    }

    func loadData() {
        loadTask?.cancel()
        loadTask = Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                async let quoteResult = dataService.fetchDailyQuote()
                async let announcementsResult = dataService.fetchAnnouncements()
                let quote = try await quoteResult
                let anns = (try? await announcementsResult) ?? []
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    dailyQuote = quote
                    announcements = anns
                    isLoading = false
                    // Cache daily quote for offline
                    cache.cacheDailyQuote(quote)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    // Try loading cached quote
                    if let cachedQuote = cache.loadCachedDailyQuote() {
                        dailyQuote = cachedQuote
                    } else {
                        errorMessage = "Unable to load content. Pull down to refresh."
                    }
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Cleanup

    func cancelTasks() {
        loadTask?.cancel()
        loadTask = nil
    }
}
