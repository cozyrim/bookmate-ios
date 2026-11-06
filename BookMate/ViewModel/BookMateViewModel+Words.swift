import Foundation

extension BookMateViewModel {
    var archiveFilteredWords: [Word] { wordFeature.filteredWords(books: books, booksOnShelf: booksOnShelf) }

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


    func clearSearchState(searchMode mode: SearchMode? = nil) {
        wordFeature.clearSearchState(searchMode: mode)
    }

    func prepareWordSaveAfterBookRegistration() {
        wordFeature.prepareWordSaveAfterBookRegistration()
    }

    func presentWordSaveAfterBookRegistration(registeredBookId: UUID?) {
        wordFeature.presentWordSaveAfterBookRegistration(registeredBookId: registeredBookId)
    }

    func cancelWordSaveAfterBookRegistration() {
        wordFeature.cancelWordSaveAfterBookRegistration()
    }

    func saveWord(
        bookId: UUID,
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String
    ) {
        wordFeature.saveWord(bookId: bookId, text: text, meaning: meaning, partOfSpeech: partOfSpeech, exampleSentence: exampleSentence, targetCode: targetCode)
    }

    func saveDictionaryResult(to bookId: UUID, exampleSentence: String?) async -> Bool {
        await wordFeature.saveDictionaryResult(to: bookId, exampleSentence: exampleSentence, dictionarySearchResult: dictionarySearchResult, booksOnShelf: booksOnShelf)
    }

    func savedWords(for bookId: UUID) -> [Word] {
        wordFeature.savedWords(for: bookId)
    }

    func loadSavedWords() async {
        await wordFeature.loadSavedWords()
    }

    func deleteWord(_ word: Word, successMessage: String = "단어를 삭제했어요.") async -> Bool {
        await wordFeature.deleteWord(word, successMessage: successMessage)
    }

    func updateWord(
        _ word: Word,
        successMessage: String = "단어 기록을 수정했어요.",
        analyticsAction: String = "edit"
    ) async -> Bool {
        await wordFeature.updateWord(word, successMessage: successMessage, analyticsAction: analyticsAction)
    }

    func moveWord(_ word: Word, to book: Book) async -> Bool {
        await wordFeature.moveWord(word, to: book)
    }
}
