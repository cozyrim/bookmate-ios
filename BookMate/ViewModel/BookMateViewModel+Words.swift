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

    func performSearch() async { await searchFeature.performSearch(savedWords: savedWords, books: books) }
    func clearSearch() { searchFeature.clearSearch() }
    func clearSearchResults() { searchFeature.clearSearchResults() }
    func searchSavedWords() { searchFeature.searchSavedWords(savedWords: savedWords, books: books) }
    func searchDictionaryEntry() async { await searchFeature.searchDictionaryEntry() }
    func fetchDictionarySuggestions() async { await searchFeature.fetchDictionarySuggestions() }
    func selectDictionaryEntry(_ entry: DictionaryEntry) async { await searchFeature.selectDictionaryEntry(entry) }
    func loadRecentSearches() { searchFeature.loadRecentSearches() }
    func addRecentSearch(_ word: String) { searchFeature.addRecentSearch(word) }
    func removeRecentSearch(_ word: String) { searchFeature.removeRecentSearch(word) }
    func setRecentSearchOwner(userId: UUID?) { searchFeature.setRecentSearchOwner(userId: userId) }


    // 화면 전환 시 검색 상태와 단어 저장 흐름을 함께 초기화한다.
    func clearSearchState(searchMode mode: SearchMode? = nil) {
        if let mode {
            searchMode = mode
        }

        clearSearch()
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
            BMAnalytics.wordSaveFailed(reason: "missing_dictionary_result")
            return false
        }

        guard booksOnShelf.contains(where: { $0.id == bookId }) else {
            operationErrorMessage = "책을 먼저 등록해 주세요."
            showToast("책을 먼저 등록해 주세요.", style: .error)
            BMAnalytics.wordSaveFailed(reason: "missing_book")
            return false
        }

        let alreadySaved = savedWords.contains {
            $0.bookId == bookId
            && $0.targetCode == dictionarySearchResult.targetCode
        }

        guard !alreadySaved else {
            operationErrorMessage = nil
            showToast("이미 이 책에 저장한 단어예요.", style: .info)
            BMAnalytics.wordSaveFailed(reason: "duplicate")
            return false
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SaveDictionaryWordAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SaveDictionaryWordAPI", id: signpostID)
        }

        do {
            let savedWord = try await wordRepository.saveWord(
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
            BMAnalytics.wordSaved(hasExampleSentence: exampleSentence?.isEmpty == false)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "단어 저장에 실패했습니다."
            showToast("단어 저장에 실패했어요.", style: .error)
            BMAnalytics.wordSaveFailed(reason: "api_error")
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
            savedWords = try await wordRepository.fetchWords()
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
            try await wordRepository.deleteWord(id: word.id)

            savedWords.removeAll { $0.id == word.id }
            savedWordSearchResults.removeAll { $0.id == word.id }

            operationErrorMessage = nil
            showToast(successMessage, style: .success)
            BMAnalytics.wordDeleted()
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
    func updateWord(
        _ word: Word,
        successMessage: String = "단어 기록을 수정했어요.",
        analyticsAction: String = "edit"
    ) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("UpdateWordAPI", id: signpostID)

        defer {
            PerformanceLogger.end("UpdateWordAPI", id: signpostID)
        }

        do {
            let updatedWord = try await wordRepository.updateWord(word)

            if let index = savedWords.firstIndex(where: { $0.id == updatedWord.id }) {
                savedWords[index] = updatedWord
            }

            if let index = savedWordSearchResults.firstIndex(where: { $0.id == updatedWord.id }) {
                savedWordSearchResults[index] = updatedWord
            }

            operationErrorMessage = nil
            showToast(successMessage, style: .success)
            BMAnalytics.wordUpdated(action: analyticsAction)
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

        return await updateWord(
            movedWord,
            successMessage: "단어를 다른 책으로 이동했어요.",
            analyticsAction: "move"
        )
    }

}
