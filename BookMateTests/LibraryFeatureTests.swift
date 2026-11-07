import XCTest
import Combine
@testable import BookMate

@MainActor
final class LibraryFeatureTests: XCTestCase {
    func testDuplicateBookIsRejectedBeforeRepositoryWrite() async {
        let repository = LibraryBookStub()
        let model = makeModel(repository: repository)
        model.books = [Book(title: "같은 책", author: "저자", imageName: "", progress: 0)]

        do {
            _ = try await model.registerBook(draft: BookRegistrationDraft(title: " 같은 책 ", author: "저자", totalPages: 100))
            XCTFail("Duplicate book must not be registered")
        } catch BookRegistrationError.duplicate {
        } catch { XCTFail("Unexpected error: \(error)") }

        XCTAssertEqual(repository.createCount, 0)
        XCTAssertEqual(model.books.count, 1)
    }

    func testConcurrentRegistrationSharesOneRepositoryRequest() async throws {
        let repository = LibraryBookStub()
        let model = makeModel(repository: repository)
        let draft = BookRegistrationDraft(title: "새 책", author: "저자", totalPages: 100)
        let first = Task { try await model.registerBook(draft: draft) }
        await repository.waitForCreate()
        let secondEntered = expectation(description: "Second registration started")
        let second = Task {
            secondEntered.fulfill()
            return try await model.registerBook(draft: draft)
        }
        await fulfillment(of: [secondEntered], timeout: 3)
        let response = Book(title: draft.title, author: draft.author, imageName: "", progress: 0, totalPages: 100, currentPage: 0)
        repository.finishCreate(with: response)
        let results = try await [first.value, second.value]

        XCTAssertEqual(results.map(\.id), [response.id, response.id])
        XCTAssertEqual(repository.createCount, 1)
        XCTAssertEqual(model.books.map(\.id), [response.id])
        XCTAssertEqual(model.shelfBooks.map(\.bookId), [response.id])
    }

    func testSuccessfulBookDeletionRemovesRelatedWordsAndShelfEntry() async {
        let repository = LibraryBookStub()
        let model = makeModel(repository: repository)
        let book = Book(title: "책", author: "저자", imageName: "", progress: 0)
        repository.records = [book]
        await model.loadBooks()
        let removed = Word(text: "삭제 대상", meaning: "뜻", partOfSpeech: "명사", exampleSentence: nil, targetCode: "1", bookId: book.id)
        let retained = Word(text: "유지 대상", meaning: "뜻", partOfSpeech: "명사", exampleSentence: nil, targetCode: "2", bookId: UUID())
        model.savedWords = [removed, retained]

        let deleted = await model.deleteBook(book)

        XCTAssertTrue(deleted)
        XCTAssertEqual(repository.deletedIDs, [book.id])
        XCTAssertTrue(model.books.isEmpty)
        XCTAssertTrue(model.shelfBooks.isEmpty)
        XCTAssertEqual(model.savedWords, [retained])
    }

    func testExistingRoomPublisherObservesTheSingleBookSource() async {
        let model = makeModel(repository: LibraryBookStub())
        var counts: [Int] = []
        let subscription = model.libraryFeature.$books.sink { counts.append($0.count) }
        let book = Book(title: "책", author: "저자", imageName: "", progress: 0)

        model.books = [book]

        XCTAssertEqual(model.libraryFeature.books, [book])
        XCTAssertEqual(counts, [0, 1])
        withExtendedLifetime(subscription) {}
    }

    func testQuickRegistrationRejectsBlankFieldsWithoutWriting() async {
        let repository = LibraryBookStub()
        let app = makeModel(repository: repository)
        let model = BookRegistrationViewModel(library: app.libraryFeature, metadata: app.dependencies.bookMetadata)
        await model.register(draft: BookRegistrationDraft(title: "  ", author: "저자", totalPages: 100))
        XCTAssertEqual(repository.createCount, 0)
        XCTAssertNil(model.savedBook)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isSaving)
    }

    func testQuickRegistrationNormalizesDefaultCategoryAndPublishesSavedBook() async {
        let repository = LibraryBookStub()
        let app = makeModel(repository: repository)
        let model = BookRegistrationViewModel(library: app.libraryFeature, metadata: app.dependencies.bookMetadata)
        let task = Task { await model.register(draft: BookRegistrationDraft(title: " 새 책 ", author: " 저자 ", totalPages: 100)) }
        await repository.waitForCreate()
        XCTAssertEqual(repository.lastTitle, "새 책")
        XCTAssertEqual(repository.lastAuthor, "저자")
        XCTAssertEqual(repository.lastCategory, "기타")
        let saved = Book(title: "새 책", author: "저자", imageName: "", progress: 0)
        repository.finishCreate(with: saved)
        await task.value
        XCTAssertEqual(model.savedBook?.id, saved.id)
        XCTAssertFalse(model.isSaving)
        XCTAssertNil(model.errorMessage)
        await model.register(draft: BookRegistrationDraft(title: "새 책", author: "저자", totalPages: 100))
        XCTAssertNil(model.savedBook, "A duplicate retry must not retain the previous successful navigation result")
        XCTAssertEqual(repository.createCount, 1)
    }

    // Keep MainActor teardown in a task on iOS 26.2 (swiftlang/swift#87316).
    func testRegistrationCompletionPreservesBookSelectionForPendingWordSave() async {
        let app = makeModel(repository: LibraryBookStub())
        let book = Book(title: "새 책", author: "저자", imageName: "", progress: 0)
        XCTAssertEqual(app.completeBookRegistration(book), 1)
        app.shouldResumeWordSaveAfterBookRegistration = true
        app.wordSaveBookIdToSelectAfterRegistration = UUID()
        XCTAssertEqual(app.completeBookRegistration(book), 0)
        XCTAssertEqual(app.wordSaveBookIdToSelectAfterRegistration, book.id)
    }

    private func makeModel(repository: LibraryBookStub) -> BookMateViewModel {
        BookMateViewModel(dependencies: AppDependencies(readingReminders: ReminderStub(), books: repository, shelfOrder: LibraryShelfOrderStub()))
    }
}

@MainActor
private final class LibraryBookStub: BookRepository {
    var records: [Book] = []
    var createCount = 0
    var lastTitle: String?
    var lastAuthor: String?
    var lastCategory: String?
    var deletedIDs: [UUID] = []
    private var createContinuation: CheckedContinuation<Book, Error>?
    private var arrival: CheckedContinuation<Void, Never>?
    func fetchBooks() async throws -> [Book] { records }
    func fetchBook(id: UUID) async throws -> Book { throw URLError(.resourceUnavailable) }
    func createBook(title: String, author: String, imageName: String, category: String, progress: Double, totalPages: Int?, currentPage: Int?, isbn: String?) async throws -> Book {
        createCount += 1
        lastTitle = title
        lastAuthor = author
        lastCategory = category
        return try await withCheckedThrowingContinuation {
            createContinuation = $0
            arrival?.resume()
            arrival = nil
        }
    }
    func waitForCreate() async {
        if createContinuation != nil { return }
        await withCheckedContinuation { arrival = $0 }
    }
    func finishCreate(with book: Book) {
        createContinuation?.resume(returning: book)
        createContinuation = nil
    }
    func updateBook(_ book: Book) async throws -> Book { book }
    func deleteBook(id: UUID) async throws { deletedIDs.append(id) }
}

@MainActor
private struct ReminderStub: ReadingReminderScheduling {
    func scheduleContinueReadingReminderIfEnabled(book: Book?, shelfBook: ShelfBook?) async {}
}

@MainActor
private final class LibraryShelfOrderStub: ShelfOrderRepository {
    private var bookIDs: [UUID] = []
    func load(ownerID: UUID?) -> [UUID] { bookIDs }
    func save(_ bookIDs: [UUID], ownerID: UUID?) { self.bookIDs = bookIDs }
    func remove(_ bookID: UUID, ownerID: UUID?) { bookIDs.removeAll { $0 == bookID } }
}
