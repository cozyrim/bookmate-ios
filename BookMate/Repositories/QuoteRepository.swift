import Foundation

protocol QuoteRepository {
    func fetchQuotes(bookId: UUID) async throws -> [Quote]
    func saveQuote(
        bookId: UUID,
        text: String,
        page: Int?,
        memo: String?
        ) async throws -> Quote
    func updateQuote(_ quote: Quote) async throws -> Quote
    func deleteQuote(id: UUID) async throws
}
