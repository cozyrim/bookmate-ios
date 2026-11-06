import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    typealias SearchMode = RecentSearchScope.Mode
    @Published var searchText = ""
    @Published var searchMode: SearchMode = .dictionary
    @Published var dictionarySearchResult: DictionaryEntry?
    @Published var savedWordSearchResults: [Word] = []
    @Published var savedBookSearchResults: [Book] = []
    @Published var isLoading = false
    @Published var dictionarySuggestions: [DictionaryEntry] = []
    @Published var recentSearches: [String] = []
    @Published var searchErrorMessage: String?
    @Published var bookSearchResults: [KakaoBook] = []
    @Published var isBookSearchLoading = false
    @Published var bookSearchErrorMessage: String?
    private var bookRequestID = UUID()
    private var dictionaryRequestID = UUID()
    var recentSearchOwnerId: UUID?
    private let dictionaryRepository: any DictionaryRepository
    private let dictionaryExampleRepository: any DictionaryExampleRepository
    private let bookSearchRepository: any BookSearchRepository
    private let recentSearchRepository: any RecentSearchRepository
    private let preferences: any SearchPreferencesRepository

    init(dependencies: AppDependencies, recentSearchRepository: (any RecentSearchRepository)? = nil) {
        dictionaryRepository = dependencies.dictionary
        dictionaryExampleRepository = dependencies.dictionaryExamples
        bookSearchRepository = dependencies.bookSearch
        self.recentSearchRepository = recentSearchRepository ?? dependencies.recentSearches
        preferences = dependencies.searchPreferences
    }

    // 현재 검색 모드에 따라 사전 API 검색 또는 저장 기록 검색을 실행한다.
    func performSearch(savedWords: [Word], books: [Book]) async {
        switch searchMode {
        case .dictionary:
                savedWordSearchResults = []
                savedBookSearchResults = []
                bookSearchResults = []
                await searchDictionaryEntry()

            case .book:
                dictionarySearchResult = nil
                dictionarySuggestions = []
                savedWordSearchResults = []
                savedBookSearchResults = []
                await searchBooks(query: searchText)
                addRecentSearch(searchText)

            case .savedWords:
                dictionarySearchResult = nil
                dictionarySuggestions = []
                bookSearchResults = []
                searchSavedWords(savedWords: savedWords, books: books)
                addRecentSearch(searchText)
            }
    }

    // 입력과 검색 결과를 비우고, 검색 모드와 단어 저장 흐름은 유지한다.
    func clearSearch() {
        searchText = ""
        clearSearchResults()
    }

    // 입력은 유지한 채 검색 결과, 오류, 로딩 상태를 비운다.
    func clearSearchResults() {
        bookRequestID = UUID()
        dictionaryRequestID = UUID()
        dictionarySearchResult = nil
        dictionarySuggestions = []
        savedWordSearchResults = []
        savedBookSearchResults = []
        bookSearchResults = []
        searchErrorMessage = nil
        bookSearchErrorMessage = nil
        isLoading = false
        isBookSearchLoading = false
    }

    // 저장된 단어와 책 목록에서 검색어가 포함된 항목을 찾는다.
    func searchSavedWords(savedWords: [Word], books: [Book]) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchErrorMessage = "검색어를 입력해 주세요."
            savedWordSearchResults = []
            savedBookSearchResults = []
            return
        }

        searchErrorMessage = nil

        savedWordSearchResults = savedWords.filter { word in
            word.text.localizedCaseInsensitiveContains(trimmed)
            || word.meaning.localizedCaseInsensitiveContains(trimmed)
            || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }

        savedBookSearchResults = books.filter { book in
            book.title.localizedCaseInsensitiveContains(trimmed)
            || book.author.localizedCaseInsensitiveContains(trimmed)
            || book.category.localizedCaseInsensitiveContains(trimmed)
        }

        if savedWordSearchResults.isEmpty && savedBookSearchResults.isEmpty {
            searchErrorMessage = "저장한 단어 또는 책에서 검색 결과가 없습니다."
        }
    }

    // MARK: - Dictionary Lookup

    // 표준국어대사전 API에서 검색어에 해당하는 단어 정보를 조회한다.
//     검색어 정리
// → 표준국어대사전 API 호출
// → 결과 후보 모으기
// → 좋은 후보 고르기
// → 화면에 보여줄 DictionaryEntry 만들기
    func searchDictionaryEntry() async {
        let trimmedSearchText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")

        guard !trimmedSearchText.isEmpty else {
            searchErrorMessage = "검색어를 입력해 주세요."
            return
        }

        let requestID = UUID()
        dictionaryRequestID = requestID
        isLoading = true
        defer {
            if dictionaryRequestID == requestID { isLoading = false }
        }
        searchErrorMessage = nil
        dictionarySearchResult = nil

        guard dictionaryRepository.isConfigured else {
            searchErrorMessage = "API 키가 설정되지 않았습니다."
            return
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SearchDictionaryAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SearchDictionaryAPI", id: signpostID)
        }

        do {
            var candidateItems = try await fetchDictionaryItems(query: trimmedSearchText)
            guard dictionaryRequestID == requestID, !Task.isCancelled else { return }

            if shouldFetchPredicateVariants(for: trimmedSearchText, items: candidateItems) {
                let predicateItems = await fetchPredicateVariantItems(
                    for: trimmedSearchText,
                    items: candidateItems
                )
                guard dictionaryRequestID == requestID, !Task.isCancelled else { return }
                candidateItems.append(contentsOf: predicateItems)
            }

            guard let selectedItem = preferredDictionaryItems(from: candidateItems, query: trimmedSearchText).first else {
                searchErrorMessage = "검색 결과가 없습니다."
                BMAnalytics.searchCompleted(mode: .dictionary, resultCount: 0)

                if suggestsSimilarWordsOnFailure {
                    await fetchDictionarySuggestions()
                }

                    return
            }

            let selectedText = normalizedDictionaryWord(selectedItem.word)
            let exampleSentence = await dictionaryExampleRepository.fetchExample(
                word: selectedText,
                targetCode: selectedItem.targetCode
            )

            guard dictionaryRequestID == requestID, !Task.isCancelled else { return }
            dictionarySearchResult = dictionaryEntry(from: selectedItem, exampleSentence: exampleSentence)
            BMAnalytics.searchCompleted(mode: .dictionary, resultCount: 1)

            addRecentSearch(trimmedSearchText)
        } catch {
            guard dictionaryRequestID == requestID, !Task.isCancelled else { return }
            searchErrorMessage = "검색 중 오류가 발생했습니다."
            BMAnalytics.searchFailed(mode: .dictionary, reason: "api_error")
            DebugLogger.log(error)
        }
    }

    // 사전 검색 실패 또는 입력 중 보조 후보로 보여줄 단어를 조회한다.
    func fetchDictionarySuggestions() async {
        let trimmed = normalizedDictionaryWord(searchText)

        guard searchMode == .dictionary else {
            dictionarySuggestions = []
            return
        }

        guard trimmed.count >= 2 else {
            dictionarySuggestions = []
            return
        }

        guard dictionaryRepository.isConfigured else {
            dictionarySuggestions = []
            return
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("FetchDictionarySuggestionsAPI", id: signpostID)

        defer {
            PerformanceLogger.end("FetchDictionarySuggestionsAPI", id: signpostID)
        }

        do {
            let fetchedItems = try await dictionaryRepository.searchItems(query: trimmed)
            guard !Task.isCancelled,
                  searchMode == .dictionary,
                  normalizedDictionaryWord(searchText) == trimmed else {
                return
            }

            var candidateItems = fetchedItems
            if shouldFetchPredicateVariants(for: trimmed, items: candidateItems) {
                let predicateItems = await fetchPredicateVariantItems(
                    for: trimmed,
                    items: candidateItems
                )
                guard !Task.isCancelled,
                      searchMode == .dictionary,
                      normalizedDictionaryWord(searchText) == trimmed else {
                    return
                }

                candidateItems.append(contentsOf: predicateItems)
            }

            dictionarySuggestions = preferredDictionaryItems(from: candidateItems, query: trimmed)
                .prefix(5)
                .map { dictionaryEntry(from: $0, exampleSentence: nil) }
        } catch {
            if Task.isCancelled { return }
            dictionarySuggestions = []
            DebugLogger.log("사전 후보 검색 실패:", error)
        }
    }

    // 같은 표제어의 다른 뜻을 선택해도 targetCode 기준으로 결과 카드를 즉시 갱신한다.
    func selectDictionaryEntry(_ entry: DictionaryEntry) async {
        dictionaryRequestID = UUID()
        isLoading = false
        dictionarySearchResult = entry
        searchErrorMessage = nil
        dictionarySuggestions = []
        addRecentSearch(entry.text)

        guard entry.exampleSentence == nil else { return }

        let exampleSentence = await dictionaryExampleRepository.fetchExample(
            word: entry.text,
            targetCode: entry.targetCode
        )

        guard dictionarySearchResult?.targetCode == entry.targetCode else { return }

        dictionarySearchResult = DictionaryEntry(
            text: entry.text,
            meaning: entry.meaning,
            partOfSpeech: entry.partOfSpeech,
            exampleSentence: exampleSentence,
            targetCode: entry.targetCode
        )
    }

    // 카카오 책 검색 API로 등록할 책 후보를 찾는다.
    func searchBooks(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            bookSearchErrorMessage = "책 제목 또는 저자를 입력해 주세요."
            return
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SearchBooksAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SearchBooksAPI", id: signpostID)
        }

        let requestID = UUID()
        bookRequestID = requestID
        isBookSearchLoading = true
        defer {
            if bookRequestID == requestID { isBookSearchLoading = false }
        }
        bookSearchErrorMessage = nil

        do {
            let results = try await bookSearchRepository.searchBooks(query: trimmed)
            guard bookRequestID == requestID, !Task.isCancelled else { return }
            bookSearchResults = results
            BMAnalytics.searchCompleted(mode: .book, resultCount: bookSearchResults.count)
        } catch {
            guard bookRequestID == requestID, !Task.isCancelled else { return }
            bookSearchResults = []
            bookSearchErrorMessage = "책 검색에 실패했습니다."
            BMAnalytics.searchFailed(mode: .book, reason: "api_error")
            DebugLogger.log("책 검색 실패:", error)
        }
    }

    // MARK: - Recent Searches

    // 현재 사용자와 검색 종류로 최근 검색어의 저장 범위를 정한다.
    private var recentSearchScope: RecentSearchScope {
        RecentSearchScope(ownerID: recentSearchOwnerId, mode: searchMode)
    }

    // 현재 범위에 저장된 최근 검색어를 화면 상태에 반영한다.
    func loadRecentSearches() {
        recentSearches = recentSearchRepository.load(for: recentSearchScope)
    }

    // 최근 검색어를 중복 없이 최신순으로 저장한다.
    func addRecentSearch(_ word: String) {
        guard recentSearchRepository.isSavingEnabled,
              let updated = RecentSearchHistory.adding(word, to: recentSearches) else { return }

        recentSearches = updated
        recentSearchRepository.save(updated, for: recentSearchScope)
    }

    // 최근 검색어에서 특정 단어를 제거한다.
    func removeRecentSearch(_ word: String) {
        recentSearches = RecentSearchHistory.removing(word, from: recentSearches)
        recentSearchRepository.save(recentSearches, for: recentSearchScope)
    }

    // 최근 검색어 저장 범위를 현재 사용자 기준으로 바꾼다.
    func setRecentSearchOwner(userId: UUID?) {
        recentSearchOwnerId = userId
        loadRecentSearches()
    }

    // 검색 실패 시 비슷한 단어를 제안할지 설정값을 읽는다.
    private var suggestsSimilarWordsOnFailure: Bool {
        preferences.suggestsSimilarWordsOnFailure
    }

    private func fetchDictionaryItems(query: String) async throws -> [StdDictItem] {
        try await dictionaryRepository.searchItems(query: query)
    }

    private func preferredDictionaryItems(from items: [StdDictItem], query: String) -> [StdDictItem] {
        var seenTargetCodes = Set<String>()
        let uniqueItems = items.filter { item in
            seenTargetCodes.insert(item.targetCode).inserted
        }

        return uniqueItems
            .enumerated()
            .sorted { lhs, rhs in
                let lhsScore = dictionaryItemScore(lhs.element, query: query)
                let rhsScore = dictionaryItemScore(rhs.element, query: query)

                if lhsScore == rhsScore {
                    return lhs.offset < rhs.offset
                }

                return lhsScore > rhsScore
            }
            .map { $0.element }
    }

    private func dictionaryItemScore(_ item: StdDictItem, query: String) -> Int {
        let word = normalizedDictionaryWord(item.word)
        var score = 0

        if word == query {
            score += 120
        } else if predicateVariantQueries(for: query).contains(word) {
            score += 110
        } else if word.hasPrefix(query) {
            score += 20
        }

        if isRootDefinition(item.sense.definition) {
            score -= 80
        } else {
            score += 40
        }

        if !isEmptyPartOfSpeech(item.pos) {
            score += 20
        }

        return score
    }

    // 추가 검색을 해야하는지를 판단 (~하다의 어근처럼 애매한 경우 추가 검색)
    private func shouldFetchPredicateVariants(for query: String, items: [StdDictItem]) -> Bool {
        guard !predicateVariantQueries(for: query, items: items).isEmpty else { return false }

        if items.contains(where: { isRootDefinition($0.sense.definition) }) {
            return true
        }

        guard let preferredItem = preferredDictionaryItems(from: items, query: query).first else {
            return true
        }

        return isRootDefinition(preferredItem.sense.definition)
    }

    private func fetchPredicateVariantItems(for query: String, items sourceItems: [StdDictItem]) async -> [StdDictItem] {
        var items: [StdDictItem] = []

        for variantQuery in predicateVariantQueries(for: query, items: sourceItems) {
            if let variantItems = try? await fetchDictionaryItems(query: variantQuery) {
                items.append(contentsOf: variantItems)
            }
        }

        return items
    }

    private func predicateVariantQueries(for query: String, items: [StdDictItem] = []) -> [String] {
        guard !query.hasSuffix("다") else { return [] }

        var seenQueries = Set<String>()
        var queries = items.compactMap { rootPredicateWord(from: $0.sense.definition) }
        queries.append(contentsOf: ["\(query)하다", "\(query)다"])

        return queries.filter { seenQueries.insert($0).inserted }
    }

    private func dictionaryEntry(from item: StdDictItem, exampleSentence: String?) -> DictionaryEntry {
        DictionaryEntry(
            text: normalizedDictionaryWord(item.word),
            meaning: normalizedDictionaryMeaning(item.sense.definition),
            partOfSpeech: item.pos.trimmingCharacters(in: .whitespacesAndNewlines),
            exampleSentence: exampleSentence,
            targetCode: item.targetCode
        )
    }

    private func normalizedDictionaryWord(_ word: String) -> String {
        word
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
    }

    private func normalizedDictionaryMeaning(_ meaning: String) -> String {
        meaning.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isRootDefinition(_ definition: String) -> Bool {
        definition.replacingOccurrences(of: " ", with: "").contains("의어근")
    }

    private func rootPredicateWord(from definition: String) -> String? {
        guard isRootDefinition(definition) else { return nil }

        let quotePairs: [(Character, Character)] = [
            ("‘", "’"),
            ("“", "”"),
            ("'", "'"),
            ("\"", "\"")
        ]

        for (openingQuote, closingQuote) in quotePairs {
            guard let openingIndex = definition.firstIndex(of: openingQuote) else { continue }
            let searchStartIndex = definition.index(after: openingIndex)

            guard let closingIndex = definition[searchStartIndex...].firstIndex(of: closingQuote) else { continue }

            let candidate = normalizedDictionaryWord(String(definition[searchStartIndex..<closingIndex]))
            if candidate.hasSuffix("다") {
                return candidate
            }
        }

        return nil
    }

    private func isEmptyPartOfSpeech(_ partOfSpeech: String) -> Bool {
        let trimmed = partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "품사 없음"
    }

}
