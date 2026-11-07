import Foundation
import Combine

enum BookRegistrationError: Error { case duplicate }

@MainActor
final class BookLibraryViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var shelfBooks: [ShelfBook] = ShelfBook.sampleShelfBooks
    @Published var bookLoadErrorMessage: String?
    @Published var pendingShelfBookPresentationID: UUID?

    private var inFlightBookRegistrationTasks: [String: Task<Book, Error>] = [:]
    private let dependencies: AppDependencies
    private let words: WordViewModel
    private let context: AppContext
    private var bookRepository: any BookRepository { dependencies.books }
    private var bookPageRepository: any BookPageRepository { dependencies.bookPages }

    init(dependencies: AppDependencies, words: WordViewModel, context: AppContext) {
        self.dependencies = dependencies
        self.words = words
        self.context = context
    }

    // 서버에서 내 책 목록을 불러오고 책장 표시용 상태를 동기화한다.
    func loadBooks() async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("LoadBooksAPI", id: signpostID)

        defer {
            PerformanceLogger.end("LoadBooksAPI", id: signpostID)
        }
        
        do {
            books = try await bookRepository.fetchBooks()
                .map { normalizedBookForReadingState($0) }
            syncShelfBooksFromBooks()
            bookLoadErrorMessage = nil
        } catch {
            if context.handleUnauthorizedIfNeeded(error) {
                bookLoadErrorMessage = nil
                return
            }

            bookLoadErrorMessage = "책 목록을 불러오지 못했습니다."
            DebugLogger.log("책 목록 조회 실패:", error)
        }
    }

    // 등록 초안으로 서버에 새 책을 저장하고 화면 상태에 즉시 반영한다.
    func registerBook(draft: BookRegistrationDraft) async throws -> Book {
        guard registeredBook(for: draft) == nil else {
            context.operationErrorMessage = nil
            context.showToast("이미 등록된 책입니다.", style: .info)
            BMAnalytics.bookCreateFailed(source: bookRegistrationAnalyticsSource(for: draft), reason: "duplicate")
            throw BookRegistrationError.duplicate
        }

        let registrationKey = bookRegistrationKey(for: draft)

        if let inFlightTask = inFlightBookRegistrationTasks[registrationKey] {
            return try await inFlightTask.value
        }

        let registrationTask = Task { @MainActor in
            try await performBookRegistration(draft: draft)
        }

        inFlightBookRegistrationTasks[registrationKey] = registrationTask

        defer {
            inFlightBookRegistrationTasks[registrationKey] = nil
        }

        return try await registrationTask.value
    }

    private func performBookRegistration(draft: BookRegistrationDraft) async throws -> Book {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("RegisterBookAPI", id: signpostID)

        defer {
            PerformanceLogger.end("RegisterBookAPI", id: signpostID)
        }

        do {
            let totalPages: Int?
            if let draftTotalPages = draft.totalPages {
                totalPages = draftTotalPages
            } else {
                totalPages = await bookPageRepository.fetchPageCount(isbn: draft.isbn)
            }

            let savedBook = try await bookRepository.createBook(
                title: draft.title,
                author: draft.author,
                imageName: draft.imageName,
                category: draft.category,
                progress: draft.progress,
                totalPages: totalPages,
                currentPage: totalPages == nil ? nil : 0,
                isbn: draft.isbn
            )
            let normalizedSavedBook = normalizedBookForReadingState(savedBook)

            if let existingIndex = books.firstIndex(where: { $0.id == normalizedSavedBook.id }) {
                books[existingIndex] = normalizedSavedBook
            } else {
                books.insert(normalizedSavedBook, at: 0)
                prependBookToSavedShelfOrder(normalizedSavedBook.id)
            }

            syncShelfBooksFromBooks()
            context.operationErrorMessage = nil
            context.showToast("책을 등록했어요.", style: .success)
            BMAnalytics.bookCreated(
                source: bookRegistrationAnalyticsSource(for: draft),
                hasISBN: !normalizeISBN(draft.isbn).isEmpty,
                hasTotalPages: totalPages != nil
            )
            return normalizedSavedBook
        } catch {
            if context.handleUnauthorizedIfNeeded(error) {
                throw error
            }

            context.operationErrorMessage = "책 등록에 실패했습니다."
            context.showToast("책 등록에 실패했어요.", style: .error)
            BMAnalytics.bookCreateFailed(source: bookRegistrationAnalyticsSource(for: draft), reason: "api_error")
            DebugLogger.log("책 등록 실패:", error)
            throw error
        }
    }

    private func bookRegistrationAnalyticsSource(for draft: BookRegistrationDraft) -> String {
        normalizeISBN(draft.isbn).isEmpty ? "manual" : "book_search"
    }

    private func bookRegistrationKey(for draft: BookRegistrationDraft) -> String {
        let normalizedISBN = normalizeISBN(draft.isbn)

        if !normalizedISBN.isEmpty {
            return "isbn:\(normalizedISBN)"
        }

        let normalizedTitle = normalizeBookIdentityText(draft.title)
        let normalizedAuthor = normalizeBookIdentityText(draft.author)
        return "title:\(normalizedTitle)|author:\(normalizedAuthor)"
    }

    // 검색 결과나 등록 초안이 이미 내 책장에 있는 책인지 찾는다.
    func registeredBook(for draft: BookRegistrationDraft) -> Book? {
        let draftTitle = normalizeBookIdentityText(draft.title)
        let draftAuthor = normalizeBookIdentityText(draft.author)

        guard !draftTitle.isEmpty else { return nil }

        return books.first { book in
            let bookTitle = normalizeBookIdentityText(book.title)
            let bookAuthor = normalizeBookIdentityText(book.author)
            let authorMatches = draftAuthor.isEmpty
                || bookAuthor.isEmpty
                || bookAuthor == draftAuthor
                || bookAuthor.contains(draftAuthor)
                || draftAuthor.contains(bookAuthor)

            return bookTitle == draftTitle && authorMatches
        }
    }

    // 책장 탭에서 해당 책 카드 위치로 이동하도록 요청한다.
    func requestShelfBookPresentation(bookId: UUID) {
        pendingShelfBookPresentationID = bookId
    }

    // 길게 누른 책 카드를 다른 카드 위로 옮겼을 때 책장 순서를 갱신한다.
    func moveShelfBook(_ draggedBookID: UUID, to targetBookID: UUID) {
        guard draggedBookID != targetBookID,
              let sourceIndex = shelfBooks.firstIndex(where: { $0.bookId == draggedBookID }),
              let targetIndex = shelfBooks.firstIndex(where: { $0.bookId == targetBookID }) else {
            return
        }

        var reorderedShelfBooks = shelfBooks
        let draggedShelfBook = reorderedShelfBooks.remove(at: sourceIndex)
        reorderedShelfBooks.insert(draggedShelfBook, at: targetIndex)
        shelfBooks = reorderedShelfBooks
        saveShelfBookOrder()
    }

    private func normalizeISBN(_ isbn: String) -> String {
        var bestCandidate = ""

        for candidate in isbn.split(whereSeparator: \.isWhitespace) {
            let cleaned = candidate
                .uppercased()
                .filter { $0.isNumber || $0 == "X" }

            if cleaned.count == 13 {
                return cleaned
            }

            if bestCandidate.isEmpty, cleaned.count == 10 {
                bestCandidate = cleaned
            }
        }

        return bestCandidate
    }

    private func normalizeBookIdentityText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { !$0.isWhitespace && $0 != "," && $0 != "." && $0 != "·" }
    }

    // 서버에서 책을 삭제하고 관련 로컬 상태도 함께 제거한다.
    func deleteBook(_ book: Book) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("DeleteBookAPI", id: signpostID)

        defer {
            PerformanceLogger.end("DeleteBookAPI", id: signpostID)
        }

        do {
            try await bookRepository.deleteBook(id: book.id)

            books.removeAll { $0.id == book.id }
            words.savedWords.removeAll { $0.bookId == book.id }
            shelfBooks.removeAll { $0.bookId == book.id }
            removeBookFromSavedShelfOrder(book.id)

            context.operationErrorMessage = nil
            context.showToast("책을 삭제했어요.", style: .success)
            BMAnalytics.bookDeleted()
            await rescheduleContinueReadingReminderIfNeeded()
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }

            context.operationErrorMessage = "책 삭제에 실패했습니다."
            context.showToast("책 삭제에 실패했어요.", style: .error)
            DebugLogger.log("책 삭제 실패:", error)
            return false
        }
    }

    func changeReadingStatus(bookID: UUID, to status: ReadingStatus) async -> Bool {
        guard let book = book(for: bookID) else { return false }
        if book.readingStatus == status { return true }
        let reset = status == .wantToRead || (book.progress >= 0.999 && status != .completed)
        let updated = Book(
            id: book.id, title: book.title, author: book.author, imageName: book.imageName,
            category: book.category, progress: status == .completed ? 1 : (reset ? 0 : book.progress),
            totalPages: book.totalPages,
            currentPage: status == .completed ? (book.totalPages ?? book.currentPage) : (reset ? (book.totalPages == nil ? nil : 0) : book.currentPage),
            rating: book.rating, review: book.review, readingStatus: status,
            startDate: book.startDate, endDate: book.endDate
        )
        return await updateBook(updated, successMessage: "독서 상태를 바꿨어요.")
    }

    // 책 정보와 독서 상태를 서버에 수정 요청하고 로컬 상태를 갱신한다.
    func updateBook(_ book: Book, successMessage: String = "책 정보를 수정했어요.") async -> Bool {
        let bookToUpdate = normalizedBookForReadingState(book)

        if isRunningForPreview {
            if let index = books.firstIndex(where: { $0.id == bookToUpdate.id }) {
                books[index] = bookToUpdate
            }

            syncShelfBooksFromBooks()
            context.operationErrorMessage = nil
            context.showToast(successMessage, style: .success)
            BMAnalytics.readingProgressUpdated(
                progressBucket: readingProgressBucket(bookToUpdate.progress),
                readingStatus: bookToUpdate.readingStatus
            )
            await rescheduleContinueReadingReminderIfNeeded()
            return true
        }

        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("UpdateBookAPI", id: signpostID)

        defer {
            PerformanceLogger.end("UpdateBookAPI", id: signpostID)
        }

        do {
            let updatedBook = normalizedBookForReadingState(
                try await bookRepository.updateBook(bookToUpdate)
            )

            if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
                books[index] = updatedBook

                if let shelfIndex = shelfBooks.firstIndex(where: { $0.bookId == updatedBook.id }) {
                    shelfBooks[shelfIndex].progress = updatedBook.progress
                    shelfBooks[shelfIndex].status = updatedBook.readingStatus ?? .reading
                    shelfBooks[shelfIndex].updatedAt = Date()
                }
            }

            context.operationErrorMessage = nil
            context.showToast(successMessage, style: .success)
            BMAnalytics.readingProgressUpdated(
                progressBucket: readingProgressBucket(updatedBook.progress),
                readingStatus: updatedBook.readingStatus
            )
            await rescheduleContinueReadingReminderIfNeeded()
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }

            context.operationErrorMessage = "책 수정에 실패했습니다."
            context.showToast("책 수정에 실패했어요.", style: .error)
            DebugLogger.log("책 수정 실패:", error)
            return false
        }
    }

    // ISBN으로 페이지 수를 조회해 책 등록 폼의 페이지 값을 자동 입력한다.
    func lookupBookPageCount(isbn: String) async -> Int? {
        await bookPageRepository.fetchPageCount(isbn: isbn)
    }

    private func readingProgressBucket(_ progress: Double) -> String {
        switch progress {
        case ..<0.01:
            return "0"
        case ..<0.25:
            return "1_24"
        case ..<0.5:
            return "25_49"
        case ..<0.75:
            return "50_74"
        case ..<0.999:
            return "75_99"
        default:
            return "100"
        }
    }

    // 책장 카드가 참조하는 ShelfBook에 해당하는 책 정보를 찾는다.
    func book(for shelfBook: ShelfBook) -> Book? {
        books.first { $0.id == shelfBook.bookId }
    }

    // 상세 화면 이동 시 bookId에 해당하는 책 정보를 찾는다.
    func book(for bookId: UUID) -> Book? {
        books.first { $0.id == bookId }
    }

    // 진행률, 공개 여부, 독서 상태 표시를 위해 책장 상태를 찾는다.
    func shelfBook(for bookId: UUID) -> ShelfBook? {
        shelfBooks.first { $0.bookId == bookId }
    }

    var latestReadingBookForReminder: (book: Book, shelfBook: ShelfBook)? {
        shelfBooks
            .filter { shelfBook in
                shelfBook.status == .reading &&
                shelfBook.progress > 0 &&
                shelfBook.progress < 0.999
            }
            .sorted { $0.updatedAt > $1.updatedAt }
            .compactMap { shelfBook -> (book: Book, shelfBook: ShelfBook)? in
                guard let book = book(for: shelfBook) else { return nil }
                return (book, shelfBook)
            }
            .first
    }

    // REST Book 데이터를 책장 렌더링용 ShelfBook 상태로 변환한다.
    private func makeShelfBook(from book: Book) -> ShelfBook {
        let normalizedBook = normalizedBookForReadingState(book)

        return ShelfBook(
            id: "shelf-\(normalizedBook.id.uuidString)",
            ownerId: "current-user",
            bookId: normalizedBook.id,
            progress: normalizedBook.progress,
            status: normalizedBook.readingStatus ?? .reading,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // books 배열을 기준으로 shelfBooks를 다시 만들되, 사용자가 정한 책장 순서는 유지한다.
    private func syncShelfBooksFromBooks() {
        let shelfBooksByBookID = Dictionary(
            uniqueKeysWithValues: books.map { book in
                (book.id, makeShelfBook(from: book))
            }
        )
        let savedOrder = savedShelfBookOrder()
        let savedBookIDs = Set(savedOrder)
        let orderedBookIDs = savedOrder.filter { shelfBooksByBookID[$0] != nil }
            + books.map(\.id).filter { !savedBookIDs.contains($0) }

        shelfBooks = orderedBookIDs.compactMap { shelfBooksByBookID[$0] }
    }

    private func savedShelfBookOrder() -> [UUID] {
        dependencies.shelfOrder.load(ownerID: context.currentUserId)
    }

    private func saveShelfBookOrder() {
        dependencies.shelfOrder.save(shelfBooks.map(\.bookId), ownerID: context.currentUserId)
    }

    private func prependBookToSavedShelfOrder(_ bookID: UUID) {
        var order = savedShelfBookOrder()
        order.removeAll { $0 == bookID }
        order.insert(bookID, at: 0)
        dependencies.shelfOrder.save(order, ownerID: context.currentUserId)
    }

    private func removeBookFromSavedShelfOrder(_ bookID: UUID) {
        dependencies.shelfOrder.remove(bookID, ownerID: context.currentUserId)
    }

    private func rescheduleContinueReadingReminderIfNeeded() async {
        let reminderBook = latestReadingBookForReminder
        await dependencies.readingReminders.scheduleContinueReadingReminderIfEnabled(
            book: reminderBook?.book,
            shelfBook: reminderBook?.shelfBook
        )
    }

    private func normalizedBookForReadingState(_ book: Book) -> Book {
        let clampedProgress = min(max(book.progress, 0), 1)
        let isWantToRead = book.readingStatus == .wantToRead
        let isCompleted = clampedProgress >= 0.999
        let normalizedStatus: ReadingStatus?

        if isWantToRead {
            normalizedStatus = .wantToRead
        } else if isCompleted {
            normalizedStatus = .completed
        } else if book.readingStatus == .completed {
            normalizedStatus = .reading
        } else {
            normalizedStatus = book.readingStatus
        }

        let normalizedProgress = isWantToRead ? 0 : clampedProgress
        let normalizedCurrentPage: Int?

        if isWantToRead {
            normalizedCurrentPage = book.totalPages == nil ? nil : 0
        } else if isCompleted {
            normalizedCurrentPage = book.totalPages ?? book.currentPage
        } else {
            normalizedCurrentPage = book.currentPage
        }

        return Book(
            id: book.id,
            title: book.title,
            author: book.author,
            imageName: book.imageName,
            category: book.category,
            progress: normalizedProgress,
            totalPages: book.totalPages,
            currentPage: normalizedCurrentPage,
            rating: book.rating,
            review: book.review,
            readingStatus: normalizedStatus,
            startDate: book.startDate,
            endDate: book.endDate
        )
    }

    // 책장에 표시할 Book 목록을 ShelfBook 순서에 맞춰 만든다.
    var booksOnShelf: [Book] {
        shelfBooks.compactMap { shelfBook in
            book(for: shelfBook)
        }
    }

    // 현재 선택된 카테고리에 속한 책 목록을 반환한다.
    var booksInSelectedCategory: [Book] {
        guard let category = words.archiveSelectedCategory else {
            return booksOnShelf
        }
        return books.filter { $0.category == category }
    }

    // Xcode Preview 실행 여부를 확인해 네트워크 요청을 피한다.
    private var isRunningForPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
