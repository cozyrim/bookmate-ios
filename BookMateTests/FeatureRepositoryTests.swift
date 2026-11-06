import XCTest
import Combine
@testable import BookMate

@MainActor
final class FeatureRepositoryTests: XCTestCase {
    func testQuoteSaveUsesInjectedRepositoryAndNotifiesExistingScreens() async {
        let repository = QuoteRepositoryStub()
        let quote = Quote(text: "서버가 저장한 문장", bookId: UUID())
        repository.savedQuote = quote
        let model = BookMateViewModel(dependencies: AppDependencies(quotes: repository))
        var notifications = 0
        let subscription = model.objectWillChange.sink { notifications += 1 }

        let saved = await model.saveQuote(bookId: quote.bookId, text: quote.text, page: nil, memo: nil)

        XCTAssertTrue(saved)
        XCTAssertEqual(repository.savedBookID, quote.bookId)
        XCTAssertEqual(model.quotes, [quote])
        XCTAssertEqual(model.quoteFeature.quotes, [quote])
        XCTAssertGreaterThan(notifications, 0)
        withExtendedLifetime(subscription) {}
    }

    func testQuoteFailurePreservesExistingRecordAndReportsError() async {
        let repository = QuoteRepositoryStub()
        let model = BookMateViewModel(dependencies: AppDependencies(quotes: repository))
        let previous = Quote(text: "기존 문장", bookId: UUID())
        model.quotes = [previous]

        let saved = await model.saveQuote(bookId: previous.bookId, text: "새 문장", page: nil, memo: nil)

        XCTAssertFalse(saved)
        XCTAssertEqual(model.quotes, [previous])
        XCTAssertNotNil(model.operationErrorMessage)
    }

    func testUnauthorizedLoadUsesSharedSessionExpirySignal() async {
        let repository = QuoteRepositoryStub()
        repository.loadError = APIError.unauthorized
        let model = BookMateViewModel(dependencies: AppDependencies(quotes: repository))

        await model.loadQuotes(bookId: UUID())

        XCTAssertTrue(model.didReceiveUnauthorized)
        XCTAssertNil(model.quoteLoadErrorMessage)
        XCTAssertNotNil(model.toast)
    }

    func testMemoSaveMaintainsDateOrderInSharedScreenState() async {
        let repository = MemoRepositoryStub()
        let bookID = UUID()
        repository.savedMemo = ReadingMemo(bookId: bookID, date: "2026-01-01", text: "새 메모")
        let model = BookMateViewModel(dependencies: AppDependencies(memos: repository))
        let previous = ReadingMemo(bookId: bookID, date: "2026-02-01", text: "기존 메모")
        model.readingMemos = [previous]

        let saved = await model.saveReadingMemo(bookId: bookID, date: "2026-01-01", page: nil, text: "새 메모")

        XCTAssertTrue(saved)
        XCTAssertEqual(model.readingMemos.map(\.date), ["2026-01-01", "2026-02-01"])
        XCTAssertEqual(model.memoFeature.readingMemos, model.readingMemos)
    }

    func testReviewSaveUsesServerResponseWithoutDuplicatingExistingReview() async {
        let repository = ReviewRepositoryStub()
        let original = Review(id: UUID(), ownerId: UUID(), ownerNickname: "사용자",
                              bookId: UUID(), rating: 1, content: "이전", isPublic: false,
                              createdAt: Date(), updatedAt: Date())
        var response = original
        response.rating = 5
        response.content = "서버 응답"
        repository.savedReview = response
        let model = BookMateViewModel(dependencies: AppDependencies(reviews: repository))
        model.reviews = [original]

        let saved = await model.saveReview(bookId: original.bookId, rating: 5, content: "입력", isPublic: false)

        XCTAssertTrue(saved)
        XCTAssertEqual(model.reviews, [response])
        XCTAssertEqual(model.reviewFeature.reviews, [response])
    }

    func testBookLoadUsesInjectedRepositoryAndKeepsReadingNormalization() async {
        let repository = BookRepositoryStub()
        repository.records = [Book(title: "책", author: "저자", imageName: "", progress: 1.5, readingStatus: .reading)]
        let model = BookMateViewModel(dependencies: AppDependencies(books: repository, shelfOrder: ShelfOrderStub()))

        await model.loadBooks()

        XCTAssertEqual(repository.loadCount, 1)
        XCTAssertEqual(model.books.first?.progress, 1)
        XCTAssertEqual(model.books.first?.readingStatus, .completed)
        XCTAssertEqual(model.shelfBooks.first?.bookId, repository.records.first?.id)
        XCTAssertNil(model.bookLoadErrorMessage)
    }

    func testFailedWordDeletionDoesNotRemoveExistingWord() async {
        let repository = WordRepositoryStub()
        let model = BookMateViewModel(dependencies: AppDependencies(words: repository))
        let word = Word(text: "단어", meaning: "뜻", partOfSpeech: "명사", exampleSentence: nil, targetCode: "1", bookId: UUID())
        model.savedWords = [word]

        let deleted = await model.deleteWord(word)

        XCTAssertFalse(deleted)
        XCTAssertEqual(repository.deletedID, word.id)
        XCTAssertEqual(model.savedWords, [word])
        XCTAssertNotNil(model.operationErrorMessage)
    }

    func testShelfOrderRetainsExistingFormatAndSeparatesOwners() async throws {
        let suite = "BookMateTests.ShelfOrder.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsShelfOrderRepository(defaults: defaults)
        let owner = UUID()
        let first = UUID()
        let second = UUID()
        defaults.set([first.uuidString, second.uuidString], forKey: "shelfBookOrder.guest")

        XCTAssertEqual(repository.load(ownerID: nil), [first, second])
        XCTAssertEqual(repository.load(ownerID: owner), [])
        repository.save([second], ownerID: owner)
        repository.remove(first, ownerID: nil)
        XCTAssertEqual(repository.load(ownerID: nil), [second])
        XCTAssertEqual(defaults.stringArray(forKey: "shelfBookOrder.\(owner.uuidString)"), [second.uuidString])
    }
}

private enum RepositoryStubError: Error { case unexpectedCall }

@MainActor
private final class QuoteRepositoryStub: QuoteRepository {
    var savedQuote: Quote?
    var savedBookID: UUID?
    var loadError: Error = RepositoryStubError.unexpectedCall
    func fetchQuotes(bookId: UUID) async throws -> [Quote] { throw loadError }
    func saveQuote(bookId: UUID, text: String, page: Int?, memo: String?) async throws -> Quote {
        savedBookID = bookId
        guard let savedQuote else { throw RepositoryStubError.unexpectedCall }
        return savedQuote
    }
    func updateQuote(_ quote: Quote) async throws -> Quote { throw RepositoryStubError.unexpectedCall }
    func deleteQuote(id: UUID) async throws { throw RepositoryStubError.unexpectedCall }
}

@MainActor
private final class MemoRepositoryStub: ReadingMemoRepository {
    var savedMemo: ReadingMemo?
    func fetchMemos(bookId: UUID) async throws -> [ReadingMemo] { throw RepositoryStubError.unexpectedCall }
    func saveMemo(bookId: UUID, date: String, page: Int?, text: String) async throws -> ReadingMemo {
        guard let savedMemo else { throw RepositoryStubError.unexpectedCall }
        return savedMemo
    }
    func updateMemo(_ memo: ReadingMemo) async throws -> ReadingMemo { throw RepositoryStubError.unexpectedCall }
    func deleteMemo(id: UUID) async throws { throw RepositoryStubError.unexpectedCall }
}

@MainActor
private final class ReviewRepositoryStub: ReviewRepository {
    var savedReview: Review?
    func fetchMyReview(bookId: UUID) async throws -> Review? { throw RepositoryStubError.unexpectedCall }
    func saveReview(bookId: UUID, rating: Int, content: String, isPublic: Bool) async throws -> Review {
        guard let savedReview else { throw RepositoryStubError.unexpectedCall }
        return savedReview
    }
    func fetchPublicReviews(isbn: String, title: String, author: String) async throws -> [Review] { throw RepositoryStubError.unexpectedCall }
}

@MainActor
private final class BookRepositoryStub: BookRepository {
    var records: [Book] = []
    var loadCount = 0
    func fetchBooks() async throws -> [Book] { loadCount += 1; return records }
    func fetchBook(id: UUID) async throws -> Book { throw RepositoryStubError.unexpectedCall }
    func createBook(title: String, author: String, imageName: String, category: String, progress: Double, totalPages: Int?, currentPage: Int?, isbn: String?) async throws -> Book { throw RepositoryStubError.unexpectedCall }
    func updateBook(_ book: Book) async throws -> Book { throw RepositoryStubError.unexpectedCall }
    func deleteBook(id: UUID) async throws { throw RepositoryStubError.unexpectedCall }
}

@MainActor
private final class ShelfOrderStub: ShelfOrderRepository {
    func load(ownerID: UUID?) -> [UUID] { [] }
    func save(_ bookIDs: [UUID], ownerID: UUID?) {}
    func remove(_ bookID: UUID, ownerID: UUID?) {}
}

@MainActor
private final class WordRepositoryStub: WordRepository {
    var deletedID: UUID?
    func fetchWords() async throws -> [Word] { throw RepositoryStubError.unexpectedCall }
    func fetchWords(bookId: UUID) async throws -> [Word] { throw RepositoryStubError.unexpectedCall }
    func saveWord(bookId: UUID, text: String, meaning: String, partOfSpeech: String, exampleSentence: String?, targetCode: String) async throws -> Word { throw RepositoryStubError.unexpectedCall }
    func updateWord(_ word: Word) async throws -> Word { throw RepositoryStubError.unexpectedCall }
    func deleteWord(id: UUID) async throws { deletedID = id; throw RepositoryStubError.unexpectedCall }
}
