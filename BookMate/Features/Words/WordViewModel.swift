import Foundation
import Combine

@MainActor
final class WordViewModel: ObservableObject {
    typealias SearchMode = RecentSearchScope.Mode
    enum ArchiveSortOrder: String, CaseIterable {
        case latest = "최신순"
        case oldest = "오래된 순"
        case alphabetical = "가나다순"
    }

    @Published var savedWords: [Word] = []
    @Published var wordLoadErrorMessage: String?
    @Published var archiveSelectedCategory: String? = nil
    @Published var archiveSelectedBookId: UUID? = nil
    @Published var archiveSortOrder: ArchiveSortOrder = .latest
    @Published var isWordSaveSheetPresented = false
    @Published var shouldResumeWordSaveAfterBookRegistration = false
    @Published var isWordSaveResumeSheetPresented = false
    @Published var wordSaveBookIdToSelectAfterRegistration: UUID?

    private let wordRepository: any WordRepository
    private let search: SearchViewModel
    private let context: AppContext

    init(repository: any WordRepository, search: SearchViewModel, context: AppContext) {
        self.wordRepository = repository
        self.search = search
        self.context = context
    }

    // MARK: - Archive Filtering

    // 단어 아카이브 화면에서 선택된 카테고리, 책, 정렬 기준을 반영한 단어 목록이다.
    func filteredWords(books: [Book], booksOnShelf: [Book]) -> [Word] {
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

    // 화면 전환 시 검색 상태와 단어 저장 흐름을 함께 초기화한다.
    func clearSearchState(searchMode mode: SearchMode? = nil) {
        if let mode {
            search.searchMode = mode
        }

        search.clearSearch()
        isWordSaveSheetPresented = false
        shouldResumeWordSaveAfterBookRegistration = false
        isWordSaveResumeSheetPresented = false
        wordSaveBookIdToSelectAfterRegistration = nil
    }

    // 단어 저장 도중 원하는 책이 없어 책 등록으로 이동할 때 현재 단어 저장 맥락을 유지한다.
    func prepareWordSaveAfterBookRegistration() {
        context.operationErrorMessage = nil
        isWordSaveSheetPresented = false
        isWordSaveResumeSheetPresented = false
        shouldResumeWordSaveAfterBookRegistration = true
        wordSaveBookIdToSelectAfterRegistration = nil
    }

    // 책 등록 완료 후 기존 사전 검색 결과가 남아 있으면 홈 화면 위에 단어 저장 시트를 다시 연다.
    func presentWordSaveAfterBookRegistration(registeredBookId: UUID?) {
        guard shouldResumeWordSaveAfterBookRegistration else { return }

        guard search.dictionarySearchResult != nil else {
            shouldResumeWordSaveAfterBookRegistration = false
            isWordSaveResumeSheetPresented = false
            wordSaveBookIdToSelectAfterRegistration = nil
            context.showToast("저장할 단어를 다시 검색해 주세요.", style: .info)
            return
        }

        search.searchMode = .dictionary
        context.operationErrorMessage = nil
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
    func saveDictionaryResult(to bookId: UUID, exampleSentence: String?, dictionarySearchResult: DictionaryEntry?, booksOnShelf: [Book]) async -> Bool {
        guard let dictionarySearchResult else {
            context.operationErrorMessage = "저장할 단어를 찾지 못했습니다."
            context.showToast("저장할 단어를 찾지 못했어요.", style: .error)
            BMAnalytics.wordSaveFailed(reason: "missing_dictionary_result")
            return false
        }

        guard booksOnShelf.contains(where: { $0.id == bookId }) else {
            context.operationErrorMessage = "책을 먼저 등록해 주세요."
            context.showToast("책을 먼저 등록해 주세요.", style: .error)
            BMAnalytics.wordSaveFailed(reason: "missing_book")
            return false
        }

        let alreadySaved = savedWords.contains {
            $0.bookId == bookId
            && $0.targetCode == dictionarySearchResult.targetCode
        }

        guard !alreadySaved else {
            context.operationErrorMessage = nil
            context.showToast("이미 이 책에 저장한 단어예요.", style: .info)
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
            context.operationErrorMessage = nil
            context.showToast("단어를 저장했어요.", style: .success)
            BMAnalytics.wordSaved(hasExampleSentence: exampleSentence?.isEmpty == false)
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }

            context.operationErrorMessage = "단어 저장에 실패했습니다."
            context.showToast("단어 저장에 실패했어요.", style: .error)
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
            if context.handleUnauthorizedIfNeeded(error) {
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
            search.savedWordSearchResults.removeAll { $0.id == word.id }

            context.operationErrorMessage = nil
            context.showToast(successMessage, style: .success)
            BMAnalytics.wordDeleted()
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }

            context.operationErrorMessage = "단어 삭제에 실패했습니다."
            context.showToast("단어 삭제에 실패했어요.", style: .error)
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

            if let index = search.savedWordSearchResults.firstIndex(where: { $0.id == updatedWord.id }) {
                search.savedWordSearchResults[index] = updatedWord
            }

            context.operationErrorMessage = nil
            context.showToast(successMessage, style: .success)
            BMAnalytics.wordUpdated(action: analyticsAction)
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }

            context.operationErrorMessage = "단어 수정에 실패했습니다."
            context.showToast("단어 수정에 실패했어요.", style: .error)
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
