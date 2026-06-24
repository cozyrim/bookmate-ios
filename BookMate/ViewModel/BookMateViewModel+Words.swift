//
//  BookMateViewModel+Words.swift
//  BookMate
//
//  Created by 한채림 on 6/13/26.
//
// 단어 검색, 저장, 수정, 삭제와 최근 검색어를 관리한다.

import Foundation

extension BookMateViewModel {
    // MARK: - Archive Filtering

    // 단어 아카이브 화면에서 선택된 카테고리, 책, 정렬 기준을 반영한 단어 목록이다.
    var archiveFilteredWords: [Word] {
        var result = savedWords

        if let category = archiveSelectedCategory {
            let bookIdsInCategory = booksOnShelf
                .filter { $0.category == category }
                .map { $0.id }
            result = result.filter { bookIdsInCategory.contains($0.bookId) }
        }

        if let bookId = archiveSelectedBookId {
            result = result.filter { $0.bookId == bookId }
        }

        switch archiveSortOrder {
        case .latest:
            break
        case .oldest:
            result = result.reversed()
        case .alphabetical:
            result = result.sorted { $0.text < $1.text }
        }

        return result
    }

    // MARK: - Search

    // 현재 검색 모드에 따라 사전 API 검색 또는 저장 기록 검색을 실행한다.
    func performSearch() async {
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
                searchSavedWords()
                addRecentSearch(searchText)
            }
    }

    // 화면 전환 뒤에도 남아 있을 수 있는 임시 검색 결과를 비운다.
    func clearSearchState(searchMode mode: SearchMode? = nil) {
        if let mode {
            searchMode = mode
        }

        searchText = ""
        dictionarySearchResult = nil
        dictionarySuggestions = []
        savedWordSearchResults = []
        savedBookSearchResults = []
        bookSearchResults = []
        searchErrorMessage = nil
        bookSearchErrorMessage = nil
        isLoading = false
        isBookSearchLoading = false
        isWordSaveSheetPresented = false
        shouldResumeWordSaveAfterBookRegistration = false
        isWordSaveResumeSheetPresented = false
        wordSaveBookIdToSelectAfterRegistration = nil
    }

    // 단어 저장 도중 원하는 책이 없어 책 등록으로 이동할 때 현재 단어 저장 맥락을 유지한다.
    func prepareWordSaveAfterBookRegistration() {
        operationErrorMessage = nil
        isWordSaveSheetPresented = false
        isWordSaveResumeSheetPresented = false
        shouldResumeWordSaveAfterBookRegistration = true
        wordSaveBookIdToSelectAfterRegistration = nil
    }

    // 책 등록 완료 후 기존 사전 검색 결과가 남아 있으면 홈 화면 위에 단어 저장 시트를 다시 연다.
    func presentWordSaveAfterBookRegistration(registeredBookId: UUID?) {
        guard shouldResumeWordSaveAfterBookRegistration else { return }

        guard dictionarySearchResult != nil else {
            shouldResumeWordSaveAfterBookRegistration = false
            isWordSaveResumeSheetPresented = false
            wordSaveBookIdToSelectAfterRegistration = nil
            showToast("저장할 단어를 다시 검색해 주세요.", style: .info)
            return
        }

        searchMode = .dictionary
        operationErrorMessage = nil
        wordSaveBookIdToSelectAfterRegistration = registeredBookId ?? wordSaveBookIdToSelectAfterRegistration
        shouldResumeWordSaveAfterBookRegistration = false
        isWordSaveResumeSheetPresented = true
    }

    // 사용자가 책 등록 후 저장 흐름으로 돌아가지 않기로 했을 때 남은 재개 상태를 정리한다.
    func cancelWordSaveAfterBookRegistration() {
        isWordSaveSheetPresented = false
        isWordSaveResumeSheetPresented = false
        shouldResumeWordSaveAfterBookRegistration = false
        wordSaveBookIdToSelectAfterRegistration = nil
    }

    // 저장된 단어와 책 목록에서 검색어가 포함된 항목을 찾는다.
    func searchSavedWords() {
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

        isLoading = true
        searchErrorMessage = nil
        dictionarySearchResult = nil

        let apiKey = apiKey
        guard !apiKey.isEmpty else {
            searchErrorMessage = "API 키가 설정되지 않았습니다."
            isLoading = false
            return
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SearchDictionaryAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SearchDictionaryAPI", id: signpostID)
        }

        do {
            var candidateItems = try await fetchDictionaryItems(query: trimmedSearchText, apiKey: apiKey)

            if shouldFetchPredicateVariants(for: trimmedSearchText, items: candidateItems) {
                let predicateItems = await fetchPredicateVariantItems(for: trimmedSearchText, apiKey: apiKey)
                candidateItems.append(contentsOf: predicateItems)
            }

            guard let selectedItem = preferredDictionaryItems(from: candidateItems, query: trimmedSearchText).first else {
                searchErrorMessage = "검색 결과가 없습니다."

                if suggestsSimilarWordsOnFailure {
                    await fetchDictionarySuggestions()
                }

                isLoading = false
                return
            }

            let selectedText = normalizedDictionaryWord(selectedItem.word)
            let exampleSentence = await dictionaryExampleLookupService.fetchExample(
                word: selectedText,
                targetCode: selectedItem.targetCode
            )

            dictionarySearchResult = dictionaryEntry(from: selectedItem, exampleSentence: exampleSentence)

            addRecentSearch(trimmedSearchText)
            isLoading = false
        } catch {
            searchErrorMessage = "검색 중 오류가 발생했습니다."
            isLoading = false
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

        let apiKey = apiKey
        guard !apiKey.isEmpty else {
            dictionarySuggestions = []
            return
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("FetchDictionarySuggestionsAPI", id: signpostID)

        defer {
            PerformanceLogger.end("FetchDictionarySuggestionsAPI", id: signpostID)
        }

        do {
            let (data, response) = try await fetchDictionaryData(query: trimmed, apiKey: apiKey)
            if Task.isCancelled { return }

            if let httpResponse = response as? HTTPURLResponse {
                DebugLogger.log("후보 검색 상태 코드:", httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                dictionarySuggestions = []
                DebugLogger.log("후보 검색 응답이 비어 있음")
                return
            }

            let decodedResponse = try JSONDecoder().decode(StdDictSearchResponse.self, from: data)
            guard !Task.isCancelled,
                  searchMode == .dictionary,
                  normalizedDictionaryWord(searchText) == trimmed else {
                return
            }

            var candidateItems = decodedResponse.channel.item
            if shouldFetchPredicateVariants(for: trimmed, items: candidateItems) {
                let predicateItems = await fetchPredicateVariantItems(for: trimmed, apiKey: apiKey)
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
        dictionarySearchResult = entry
        searchErrorMessage = nil
        dictionarySuggestions = []
        addRecentSearch(entry.text)

        guard entry.exampleSentence == nil else { return }

        let exampleSentence = await dictionaryExampleLookupService.fetchExample(
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

    // MARK: - Word CRUD

    // 로컬 메모리에 단어를 임시 추가한다.
    func saveWord(
        bookId: UUID,
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String
    ) {
        let word = Word(
            text: text,
            meaning: meaning,
            partOfSpeech: partOfSpeech,
            exampleSentence: exampleSentence,
            targetCode: targetCode,
            bookId: bookId
        )

        savedWords.append(word)
    }

    // 현재 사전 검색 결과를 선택한 책에 저장한다.
    func saveDictionaryResult(to bookId: UUID, exampleSentence: String?) async -> Bool {
        guard let dictionarySearchResult else {
            operationErrorMessage = "저장할 단어를 찾지 못했습니다."
            showToast("저장할 단어를 찾지 못했어요.", style: .error)
            return false
        }

        guard booksOnShelf.contains(where: { $0.id == bookId }) else {
            operationErrorMessage = "책을 먼저 등록해 주세요."
            showToast("책을 먼저 등록해 주세요.", style: .error)
            return false
        }

        let alreadySaved = savedWords.contains {
            $0.bookId == bookId
            && $0.targetCode == dictionarySearchResult.targetCode
        }

        guard !alreadySaved else {
            operationErrorMessage = nil
            showToast("이미 이 책에 저장한 단어예요.", style: .info)
            return false
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SaveDictionaryWordAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SaveDictionaryWordAPI", id: signpostID)
        }

        do {
            let savedWord = try await wordAPIService.saveWord(
                bookId: bookId,
                text: dictionarySearchResult.text,
                meaning: dictionarySearchResult.meaning,
                partOfSpeech: dictionarySearchResult.partOfSpeech,
                exampleSentence: exampleSentence?.isEmpty == true ? nil : exampleSentence,
                targetCode: dictionarySearchResult.targetCode
            )
            savedWords.insert(savedWord, at: 0)
            operationErrorMessage = nil
            showToast("단어를 저장했어요.", style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "단어 저장에 실패했습니다."
            showToast("단어 저장에 실패했어요.", style: .error)
            DebugLogger.log("단어 저장 실패:", error)
            return false
        }
    }

    // 특정 책에 저장된 단어만 반환한다.
    func savedWords(for bookId: UUID) -> [Word] {
        savedWords.filter { $0.bookId == bookId }
    }

    // 서버에서 저장한 단어 목록을 불러온다.
    func loadSavedWords() async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("LoadSavedWordsAPI", id: signpostID)

        defer {
            PerformanceLogger.end("LoadSavedWordsAPI", id: signpostID)
        }

        do {
            savedWords = try await wordAPIService.fetchWords()
            wordLoadErrorMessage = nil
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                wordLoadErrorMessage = nil
                return
            }

            wordLoadErrorMessage = "저장한 단어를 불러오지 못했습니다."
            DebugLogger.log("저장 단어 조회 실패:", error)
        }
    }

    // 서버에서 단어를 삭제하고 로컬 목록에서도 제거한다.
    func deleteWord(_ word: Word, successMessage: String = "단어를 삭제했어요.") async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("DeleteWordAPI", id: signpostID)

        defer {
            PerformanceLogger.end("DeleteWordAPI", id: signpostID)
        }

        do {
            try await wordAPIService.deleteWord(id: word.id)

            savedWords.removeAll { $0.id == word.id }
            savedWordSearchResults.removeAll { $0.id == word.id }

            operationErrorMessage = nil
            showToast(successMessage, style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "단어 삭제에 실패했습니다."
            showToast("단어 삭제에 실패했어요.", style: .error)
            DebugLogger.log("단어 삭제 실패:", error)
            return false
        }
    }

    // 서버에서 단어 기록을 수정하고 로컬 목록을 갱신한다.
    func updateWord(_ word: Word, successMessage: String = "단어 기록을 수정했어요.") async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("UpdateWordAPI", id: signpostID)

        defer {
            PerformanceLogger.end("UpdateWordAPI", id: signpostID)
        }

        do {
            let updatedWord = try await wordAPIService.updateWord(word)

            if let index = savedWords.firstIndex(where: { $0.id == updatedWord.id }) {
                savedWords[index] = updatedWord
            }

            if let index = savedWordSearchResults.firstIndex(where: { $0.id == updatedWord.id }) {
                savedWordSearchResults[index] = updatedWord
            }

            operationErrorMessage = nil
            showToast(successMessage, style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "단어 수정에 실패했습니다."
            showToast("단어 수정에 실패했어요.", style: .error)
            DebugLogger.log("단어 수정 실패:", error)
            return false
        }
    }

    // 단어가 속한 책 id를 바꿔 다른 책으로 이동한다.
    func moveWord(_ word: Word, to book: Book) async -> Bool {
        let movedWord = Word(
            id: word.id,
            text: word.text,
            meaning: word.meaning,
            partOfSpeech: word.partOfSpeech,
            exampleSentence: word.exampleSentence,
            targetCode: word.targetCode,
            bookId: book.id
        )

        return await updateWord(movedWord, successMessage: "단어를 다른 책으로 이동했어요.")
    }

    // MARK: - Recent Searches

    // 현재 사용자별 최근 검색어 저장 키를 만든다.
    private var recentSearchesKey: String {
        let ownerKey = recentSearchOwnerId?.uuidString ?? "guest"

            switch searchMode {
            case .dictionary:
                return "recentSearches.dictionary.\(ownerKey)"
            case .book:
                return "recentSearches.book.\(ownerKey)"
            case .savedWords:
                return "recentSearches.savedWords.\(ownerKey)"
            }
    }

    // UserDefaults에 저장된 최근 검색어를 불러온다.
    func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            recentSearches = []
            return
        }

        recentSearches = decoded
    }

    // 최근 검색어를 중복 없이 최신순으로 저장한다.
    func addRecentSearch(_ word: String) {
        guard savedRecentSearches else { return }

        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recentSearches.removeAll { $0 == trimmed }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(10))

        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        }
    }

    // 최근 검색어에서 특정 단어를 제거한다.
    func removeRecentSearch(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        recentSearches.removeAll { $0 == trimmed }

        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        }
    }

    // 최근 검색어 저장 범위를 현재 사용자 기준으로 바꾼다.
    func setRecentSearchOwner(userId: UUID?) {
        recentSearchOwnerId = userId
        loadRecentSearches()
    }

    // 최근 검색어 저장 설정값을 읽는다.
    private var savedRecentSearches: Bool {
        UserDefaults.standard.object(forKey: "savesRecentSearches") as? Bool ?? true
    }

    // 검색 실패 시 비슷한 단어를 제안할지 설정값을 읽는다.
    private var suggestsSimilarWordsOnFailure: Bool {
        UserDefaults.standard.object(forKey: "suggestsSimilarWordsOnFailure") as? Bool ?? true
    }

    private func fetchDictionaryItems(query: String, apiKey: String) async throws -> [StdDictItem] {
        let (data, _) = try await fetchDictionaryData(query: query, apiKey: apiKey)
        let response = try JSONDecoder().decode(StdDictSearchResponse.self, from: data)
        return response.channel.item
    }

    private func fetchDictionaryData(query: String, apiKey: String) async throws -> (Data, URLResponse) {
        var components = URLComponents(string: "https://stdict.korean.go.kr/api/search.do")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "req_type", value: "json")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        return try await URLSession.shared.data(from: url)
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
        guard !predicateVariantQueries(for: query).isEmpty else { return false }

        guard let preferredItem = preferredDictionaryItems(from: items, query: query).first else {
            return true
        }

        return isRootDefinition(preferredItem.sense.definition)
    }

    private func fetchPredicateVariantItems(for query: String, apiKey: String) async -> [StdDictItem] {
        var items: [StdDictItem] = []

        for variantQuery in predicateVariantQueries(for: query) {
            if let variantItems = try? await fetchDictionaryItems(query: variantQuery, apiKey: apiKey) {
                items.append(contentsOf: variantItems)
            }
        }

        return items
    }

    private func predicateVariantQueries(for query: String) -> [String] {
        guard !query.hasSuffix("다") else { return [] }
        return ["\(query)하다", "\(query)다"]
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

    private func isEmptyPartOfSpeech(_ partOfSpeech: String) -> Bool {
        let trimmed = partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "품사 없음"
    }

    // 표준국어대사전 API 키를 Info.plist에서 읽고 유효성을 확인한다.
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "STDICT_API_KEY") as? String else {
            return ""
        }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "$(STDICT_API_KEY)" else {
            return ""
        }

        return trimmedKey
    }
}
