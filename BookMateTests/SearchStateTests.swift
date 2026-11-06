import XCTest
@testable import BookMate

@MainActor
final class SearchStateTests: XCTestCase {
    func testClearingSearchKeepsHistorySharedRecordsAndSaveFlow() async {
        let viewModel = makeViewModelWithSearchResults()
        let books = viewModel.books
        let savedWords = viewModel.savedWords
        let registrationID = UUID()
        viewModel.shouldResumeWordSaveAfterBookRegistration = true
        viewModel.wordSaveBookIdToSelectAfterRegistration = registrationID

        viewModel.clearSearch()

        XCTAssertEqual(viewModel.searchText, "")
        assertSearchResultsAreEmpty(in: viewModel)
        XCTAssertEqual(viewModel.searchMode, .book)
        XCTAssertEqual(viewModel.recentSearches, ["이전 검색"])
        XCTAssertEqual(viewModel.books, books)
        XCTAssertEqual(viewModel.savedWords, savedWords)
        XCTAssertTrue(viewModel.shouldResumeWordSaveAfterBookRegistration)
        XCTAssertEqual(viewModel.wordSaveBookIdToSelectAfterRegistration, registrationID)
    }

    func testClearingResultsPreservesWhitespaceInputAndPresentedSaveSheet() async {
        let viewModel = makeViewModelWithSearchResults()
        viewModel.searchText = " \n "
        viewModel.isWordSaveSheetPresented = true

        viewModel.clearSearchResults()

        XCTAssertEqual(viewModel.searchText, " \n ")
        assertSearchResultsAreEmpty(in: viewModel)
        XCTAssertTrue(viewModel.isWordSaveSheetPresented)
        XCTAssertEqual(viewModel.searchMode, .book)
        XCTAssertEqual(viewModel.recentSearches, ["이전 검색"])
    }

    func testFullResetEndsSaveFlowAndChangesModeOnlyWhenRequested() async {
        let viewModel = makeViewModelWithSearchResults()
        viewModel.isWordSaveSheetPresented = true

        viewModel.clearSearchState()

        XCTAssertEqual(viewModel.searchMode, .book)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertFalse(viewModel.isWordSaveSheetPresented)
        assertSearchResultsAreEmpty(in: viewModel)

        viewModel.shouldResumeWordSaveAfterBookRegistration = true
        viewModel.wordSaveBookIdToSelectAfterRegistration = UUID()
        viewModel.clearSearchState(searchMode: .dictionary)

        XCTAssertEqual(viewModel.searchMode, .dictionary)
        XCTAssertFalse(viewModel.shouldResumeWordSaveAfterBookRegistration)
        XCTAssertNil(viewModel.wordSaveBookIdToSelectAfterRegistration)

        viewModel.isWordSaveResumeSheetPresented = true
        viewModel.wordSaveBookIdToSelectAfterRegistration = UUID()
        viewModel.clearSearchState()

        XCTAssertFalse(viewModel.isWordSaveResumeSheetPresented)
        XCTAssertNil(viewModel.wordSaveBookIdToSelectAfterRegistration)
        XCTAssertEqual(viewModel.recentSearches, ["이전 검색"])
    }

    private func makeViewModelWithSearchResults() -> BookMateViewModel {
        let viewModel = BookMateViewModel()
        let book = Book(title: "책", author: "저자", imageName: "", progress: 0)
        let word = Word(
            text: "여행", meaning: "여행 뜻", partOfSpeech: "명사",
            exampleSentence: nil, targetCode: "1", bookId: book.id
        )
        let entry = DictionaryEntry(
            text: "여행", meaning: "여행 뜻", partOfSpeech: "명사",
            exampleSentence: nil, targetCode: "1"
        )
        viewModel.books = [book]
        viewModel.savedWords = [word]
        viewModel.searchText = "여행"
        viewModel.searchMode = .book
        viewModel.recentSearches = ["이전 검색"]
        viewModel.dictionarySearchResult = entry
        viewModel.dictionarySuggestions = [entry]
        viewModel.savedWordSearchResults = [word]
        viewModel.savedBookSearchResults = [book]
        viewModel.bookSearchResults = [KakaoBook(
            title: "검색 결과", contents: "", url: "", isbn: "1",
            datetime: "", authors: [], publisher: "", thumbnail: ""
        )]
        viewModel.searchErrorMessage = "검색 실패"
        viewModel.bookSearchErrorMessage = "책 검색 실패"
        viewModel.isLoading = true
        viewModel.isBookSearchLoading = true
        return viewModel
    }

    private func assertSearchResultsAreEmpty(
        in viewModel: BookMateViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(viewModel.dictionarySearchResult, file: file, line: line)
        XCTAssertTrue(viewModel.dictionarySuggestions.isEmpty, file: file, line: line)
        XCTAssertTrue(viewModel.savedWordSearchResults.isEmpty, file: file, line: line)
        XCTAssertTrue(viewModel.savedBookSearchResults.isEmpty, file: file, line: line)
        XCTAssertTrue(viewModel.bookSearchResults.isEmpty, file: file, line: line)
        XCTAssertNil(viewModel.searchErrorMessage, file: file, line: line)
        XCTAssertNil(viewModel.bookSearchErrorMessage, file: file, line: line)
        XCTAssertFalse(viewModel.isLoading, file: file, line: line)
        XCTAssertFalse(viewModel.isBookSearchLoading, file: file, line: line)
    }
}
