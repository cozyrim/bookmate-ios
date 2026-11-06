import XCTest
@testable import BookMate

@MainActor
final class SearchFeatureTests: XCTestCase {
    func testMissingDictionaryConfigurationReportsErrorWithoutRequest() async {
        let dictionary = DictionaryRepositoryStub()
        dictionary.isConfigured = false
        let model = SearchViewModel(dependencies: AppDependencies(dictionary: dictionary))
        model.searchText = "여행"

        await model.searchDictionaryEntry()

        XCTAssertEqual(dictionary.queries, [])
        XCTAssertEqual(model.searchErrorMessage, "API 키가 설정되지 않았습니다.")
        XCTAssertFalse(model.isLoading)
    }

    func testDictionarySearchKeepsPredicateFallbackRanking() async {
        let dictionary = DictionaryRepositoryStub()
        dictionary.items["생각"] = [StdDictItem(targetCode: "1", word: "생각", pos: "", sense: StdDictSense(definition: "‘생각하다’의 어근"))]
        dictionary.items["생각하다"] = [StdDictItem(targetCode: "2", word: "생각-하다", pos: "동사", sense: StdDictSense(definition: " 헤아리고 판단하다. "))]
        let history = SearchHistoryStub()
        let model = SearchViewModel(dependencies: AppDependencies(dictionary: dictionary, dictionaryExamples: ExampleRepositoryStub(), recentSearches: history))
        model.searchText = "생각"

        await model.searchDictionaryEntry()

        XCTAssertEqual(model.dictionarySearchResult?.targetCode, "2")
        XCTAssertEqual(model.dictionarySearchResult?.text, "생각하다")
        XCTAssertEqual(model.dictionarySearchResult?.meaning, "헤아리고 판단하다.")
        XCTAssertEqual(dictionary.queries, ["생각", "생각하다", "생각다"])
        XCTAssertEqual(model.recentSearches, ["생각"])
        XCTAssertFalse(model.isLoading)
    }

    func testSavedRecordSearchRetainsCaseInsensitiveMatching() async {
        let model = SearchViewModel(dependencies: AppDependencies())
        model.searchMode = .savedWords
        model.searchText = "swift"
        let book = Book(title: "Swift 입문", author: "저자", imageName: "", progress: 0)
        let word = Word(text: "다른 단어", meaning: "SWIFT", partOfSpeech: "명사", exampleSentence: nil, targetCode: "1", bookId: book.id)

        model.searchSavedWords(savedWords: [word], books: [book])

        XCTAssertEqual(model.savedBookSearchResults, [book])
        XCTAssertEqual(model.savedWordSearchResults, [word])
        XCTAssertNil(model.searchErrorMessage)
    }

    func testOlderBookResponseCannotReplaceNewerResults() async {
        let repository = SuspendedBookSearchRepository()
        let model = SearchViewModel(dependencies: AppDependencies(bookSearch: repository))
        let first = Task { await model.searchBooks(query: "이전") }
        await repository.waitForRequest("이전")
        let second = Task { await model.searchBooks(query: "새 검색") }
        await repository.waitForRequest("새 검색")
        repository.complete("새 검색", title: "새 결과")
        await second.value
        repository.complete("이전", title: "오래된 결과")
        await first.value

        XCTAssertEqual(model.bookSearchResults.map(\.title), ["새 결과"])
        XCTAssertFalse(model.isBookSearchLoading)
        XCTAssertNil(model.bookSearchErrorMessage)
    }

    func testClearingSearchRejectsAnAlreadyRunningResponse() async {
        let repository = SuspendedBookSearchRepository()
        let model = SearchViewModel(dependencies: AppDependencies(bookSearch: repository))
        let request = Task { await model.searchBooks(query: "여행") }
        await repository.waitForRequest("여행")

        model.clearSearch()
        repository.complete("여행", title: "늦게 도착한 결과")
        await request.value

        XCTAssertEqual(model.searchText, "")
        XCTAssertTrue(model.bookSearchResults.isEmpty)
        XCTAssertFalse(model.isBookSearchLoading)
    }
}

@MainActor
private final class DictionaryRepositoryStub: DictionaryRepository {
    var isConfigured = true
    var items: [String: [StdDictItem]] = [:]
    var queries: [String] = []
    func searchItems(query: String) async throws -> [StdDictItem] {
        queries.append(query)
        return items[query] ?? []
    }
}

@MainActor
private struct ExampleRepositoryStub: DictionaryExampleRepository {
    func fetchExample(word: String, targetCode: String) async -> String? { nil }
}

@MainActor
private final class SearchHistoryStub: RecentSearchRepository {
    let isSavingEnabled = true
    func load(for scope: RecentSearchScope) -> [String] { [] }
    func save(_ searches: [String], for scope: RecentSearchScope) {}
}

@MainActor
private final class SuspendedBookSearchRepository: BookSearchRepository {
    private var requests: [String: CheckedContinuation<[KakaoBook], Error>] = [:]
    private var arrivals: [String: CheckedContinuation<Void, Never>] = [:]
    func searchBooks(query: String) async throws -> [KakaoBook] {
        try await withCheckedThrowingContinuation { continuation in
            requests[query] = continuation
            arrivals.removeValue(forKey: query)?.resume()
        }
    }
    func waitForRequest(_ query: String) async {
        if requests[query] != nil { return }
        await withCheckedContinuation { arrivals[query] = $0 }
    }
    func complete(_ query: String, title: String) {
        requests.removeValue(forKey: query)?.resume(returning: [KakaoBook(
            title: title, contents: "", url: "", isbn: query,
            datetime: "", authors: [], publisher: "", thumbnail: ""
        )])
    }
}
