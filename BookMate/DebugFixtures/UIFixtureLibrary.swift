#if DEBUG
import Foundation

@MainActor
final class UIFixtureLibrary: BookRepository, WordRepository, QuoteRepository, ReadingMemoRepository, ReviewRepository {
    var books = [Book.dummyBooks[0]]
    var words = [Word(text: "찰나", meaning: "아주 짧은 동안", partOfSpeech: "명사", exampleSentence: nil, targetCode: "1", bookId: Book.dummyBooks[0].id)]
    var quotes: [Quote] = []
    var memos: [ReadingMemo] = []
    var reviews: [Review] = []

    init() {
        if ProcessInfo.processInfo.arguments.contains("--room-books") {
            books = Book.dummyBooks + (4...11).map { number in
                Book(title: "서재의 책 \(number)", author: "예시 저자", imageName: number == 11 ? "" : "싯타르타", progress: 0.2, readingStatus: .reading)
            }
            return
        }
        guard ProcessInfo.processInfo.arguments.contains("--home-reading-carousel") else { return }
        books = [Book(title: "완독한 책", author: "예시 저자", imageName: "싯타르타", progress: 1, readingStatus: .completed)]
            + Book.dummyBooks
            + (4...6).map { number in
                Book(title: "읽는 책 \(number)", author: "예시 저자", imageName: "싯타르타", progress: 0.2, readingStatus: .reading)
            }
    }

    func fetchBooks() async throws -> [Book] {
        return books
    }
    func fetchBook(id: UUID) async throws -> Book {
        guard let book = books.first(where: { $0.id == id }) else { throw URLError(.resourceUnavailable) }; return book
    }
    func createBook(
        title: String,
        author: String,
        imageName: String,
        category: String,
        progress: Double,
        totalPages: Int?,
        currentPage: Int?,
        isbn: String?
    ) async throws -> Book {
        if ProcessInfo.processInfo.arguments.contains("--slow-book-registration") {
            try await Task.sleep(for: .seconds(8))
        }
        let book = Book(title: title, author: author, imageName: imageName, category: category, progress: progress, totalPages: totalPages, currentPage: currentPage); books.insert(book, at: 0); return book
    }
    func updateBook(_ book: Book) async throws -> Book {
        books = books.map { $0.id == book.id ? book : $0 }; return book
    }
    func deleteBook(id: UUID) async throws {
        books.removeAll { $0.id == id }; words.removeAll { $0.bookId == id }
    }
    func fetchWords() async throws -> [Word] {
        return words
    }
    func fetchWords(bookId: UUID) async throws -> [Word] {
        return words.filter { $0.bookId == bookId }
    }
    func saveWord(
        bookId: UUID,
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String
        ) async throws -> Word {
        let word = Word(text: text, meaning: meaning, partOfSpeech: partOfSpeech, exampleSentence: exampleSentence, targetCode: targetCode, bookId: bookId); words.insert(word, at: 0); return word
    }
    func updateWord(_ word: Word) async throws -> Word {
        words = words.map { $0.id == word.id ? word : $0 }; return word
    }
    func deleteWord(id: UUID) async throws {
        words.removeAll { $0.id == id }
    }
    func fetchQuotes(bookId: UUID) async throws -> [Quote] {
        return quotes.filter { $0.bookId == bookId }
    }
    func saveQuote(
        bookId: UUID,
        text: String,
        page: Int?,
        memo: String?
        ) async throws -> Quote {
        let quote = Quote(text: text, page: page, memo: memo, bookId: bookId); quotes.insert(quote, at: 0); return quote
    }
    func updateQuote(_ quote: Quote) async throws -> Quote {
        quotes = quotes.map { $0.id == quote.id ? quote : $0 }; return quote
    }
    func deleteQuote(id: UUID) async throws {
        quotes.removeAll { $0.id == id }
    }
    func fetchMemos(bookId: UUID) async throws -> [ReadingMemo] {
        return memos.filter { $0.bookId == bookId }
    }
    func saveMemo(bookId: UUID, date: String, page: Int?, text: String) async throws -> ReadingMemo {
        let memo = ReadingMemo(bookId: bookId, date: date, page: page, text: text); memos.append(memo); return memo
    }
    func updateMemo(_ memo: ReadingMemo) async throws -> ReadingMemo {
        memos = memos.map { $0.id == memo.id ? memo : $0 }; return memo
    }
    func deleteMemo(id: UUID) async throws {
        memos.removeAll { $0.id == id }
    }
    func fetchMyReview(bookId: UUID) async throws -> Review? {
        return reviews.first { $0.bookId == bookId }
    }
    func saveReview(
        bookId: UUID,
        rating: Int,
        content: String,
        isPublic: Bool
        ) async throws -> Review {
        let review = Review(id: reviews.first(where: { $0.bookId == bookId })?.id ?? UUID(), ownerId: UIFixtureAuth.userID, ownerNickname: "독서가", bookId: bookId, rating: rating, content: content, isPublic: isPublic, createdAt: Date(), updatedAt: Date()); reviews.removeAll { $0.id == review.id }; reviews.insert(review, at: 0); return review
    }
    func fetchPublicReviews(
        isbn: String,
        title: String,
        author: String
        ) async throws -> [Review] {
        return reviews.filter(\.isPublic)
    }
}
#endif
