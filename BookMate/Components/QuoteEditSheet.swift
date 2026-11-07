import SwiftUI

struct QuoteEditSheet: View {
    @ObservedObject var viewModel: BookMateViewModel
    let quote: Quote

    var body: some View {
        QuoteComposer(title: "문장 수정", bookTitle: viewModel.book(for: quote.bookId)?.title,
                      text: quote.text, page: quote.page, memo: quote.memo) { text, page, memo in
            await viewModel.updateQuote(Quote(id: quote.id, text: text, page: page, memo: memo, bookId: quote.bookId))
        }
    }
}
