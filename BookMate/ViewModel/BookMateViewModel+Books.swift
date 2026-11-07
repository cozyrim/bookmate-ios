import Foundation

extension BookMateViewModel {
    func searchBooks(query: String) async { await searchFeature.searchBooks(query: query) }

    func loadBooks() async {
        await libraryFeature.loadBooks()
    }

    func registerBook(draft: BookRegistrationDraft) async throws -> Book {
        try await libraryFeature.registerBook(draft: draft)
    }

    /// Preserve the pending word-save selection when registration finishes without a completion screen.
    func completeBookRegistration(_ book: Book) -> Int {
        if shouldResumeWordSaveAfterBookRegistration {
            wordSaveBookIdToSelectAfterRegistration = book.id
            return 0
        }
        return 1
    }

    func registeredBook(for draft: BookRegistrationDraft) -> Book? {
        libraryFeature.registeredBook(for: draft)
    }

    func requestShelfBookPresentation(bookId: UUID) {
        libraryFeature.requestShelfBookPresentation(bookId: bookId)
    }

    func moveShelfBook(_ draggedBookID: UUID, to targetBookID: UUID) {
        libraryFeature.moveShelfBook(draggedBookID, to: targetBookID)
    }

    func deleteBook(_ book: Book) async -> Bool {
        await libraryFeature.deleteBook(book)
    }

    func updateBook(_ book: Book, successMessage: String = "책 정보를 수정했어요.") async -> Bool {
        await libraryFeature.updateBook(book, successMessage: successMessage)
    }

    func lookupBookPageCount(isbn: String) async -> Int? {
        await libraryFeature.lookupBookPageCount(isbn: isbn)
    }

    func book(for shelfBook: ShelfBook) -> Book? {
        libraryFeature.book(for: shelfBook)
    }

    func book(for bookId: UUID) -> Book? {
        libraryFeature.book(for: bookId)
    }

    func shelfBook(for bookId: UUID) -> ShelfBook? {
        libraryFeature.shelfBook(for: bookId)
    }
    var booksOnShelf: [Book] { libraryFeature.booksOnShelf }
    var booksInSelectedCategory: [Book] { libraryFeature.booksInSelectedCategory }
    var latestReadingBookForReminder: (book: Book, shelfBook: ShelfBook)? { libraryFeature.latestReadingBookForReminder }
}
