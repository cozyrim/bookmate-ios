#if DEBUG
import Foundation

@MainActor
final class UIFixtureExternal: DictionaryRepository, DictionaryExampleRepository, BookSearchRepository, BookPageRepository, BookMetadataRepository, SearchPreferencesRepository, ReadingReminderScheduling, PushTokenManaging, RecentSearchRepository, ShelfOrderRepository {
    let isConfigured = true
    let isSavingEnabled = true
    let suggestsSimilarWordsOnFailure = true
    private var history: [RecentSearchScope: [String]] = [:]
    private var shelfOrders: [String: [UUID]] = [:]
    func searchItems(query: String) async throws -> [StdDictItem] {
        [StdDictItem(targetCode: query, word: query, pos: "명사", sense: StdDictSense(definition: "\(query)의 뜻을 확인합니다."))]
    }
    func fetchExample(word: String, targetCode: String) async -> String? { "책에서 \(word)을 발견했어요." }
    func searchBooks(query: String) async throws -> [KakaoBook] {
        [KakaoBook(title: query, contents: "책 소개", url: "", isbn: "9780000000000", datetime: "", authors: ["저자"], publisher: "출판사", thumbnail: "")]
    }
    func fetchPageCount(isbn: String) async -> Int? { 200 }
    func fetchMetadata(isbn: String) async -> BookLookupMetadata? { BookLookupMetadata(pageCount: 200, description: "책 소개") }
    func scheduleContinueReadingReminderIfEnabled(book: Book?, shelfBook: ShelfBook?) async {}
    func syncTokenWithServerIfPossible(forceRefreshToken: Bool) async {}
    func disableCurrentTokenOnServer(accessToken: String?) async {}
    func load(for scope: RecentSearchScope) -> [String] {
        history[scope] ?? (ProcessInfo.processInfo.arguments.contains("--recent-search-fixture") ? ["난잡하다", "몽돌"] : [])
    }
    func save(_ searches: [String], for scope: RecentSearchScope) { history[scope] = searches }
    func load(ownerID: UUID?) -> [UUID] { shelfOrders[ownerID?.uuidString ?? "guest"] ?? [] }
    func save(_ bookIDs: [UUID], ownerID: UUID?) { shelfOrders[ownerID?.uuidString ?? "guest"] = bookIDs }
    func remove(_ bookID: UUID, ownerID: UUID?) { shelfOrders[ownerID?.uuidString ?? "guest"]?.removeAll { $0 == bookID } }
}
#endif
