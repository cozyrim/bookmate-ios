import Foundation

extension BookMateViewModel {
    func loadQuotes(bookId: UUID) async { await quoteFeature.loadQuotes(bookId: bookId) }
    func savedQuotes(for bookId: UUID) -> [Quote] { quoteFeature.savedQuotes(for: bookId) }
    func saveQuote(bookId: UUID, text: String, page: Int?, memo: String?) async -> Bool {
        await quoteFeature.saveQuote(bookId: bookId, text: text, page: page, memo: memo)
    }
    func updateQuote(_ quote: Quote) async -> Bool { await quoteFeature.updateQuote(quote) }
    func deleteQuote(_ quote: Quote) async -> Bool { await quoteFeature.deleteQuote(quote) }
}
