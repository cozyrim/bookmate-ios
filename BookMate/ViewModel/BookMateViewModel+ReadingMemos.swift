import Foundation

extension BookMateViewModel {
    func savedMemos(for bookId: UUID) -> [ReadingMemo] { memoFeature.savedMemos(for: bookId) }
    func loadReadingMemos(bookId: UUID) async { await memoFeature.loadReadingMemos(bookId: bookId) }
    func saveReadingMemo(bookId: UUID, date: String, page: Int?, text: String) async -> Bool {
        await memoFeature.saveReadingMemo(bookId: bookId, date: date, page: page, text: text)
    }
    func updateReadingMemo(_ memo: ReadingMemo) async -> Bool { await memoFeature.updateReadingMemo(memo) }
    func deleteReadingMemo(_ memo: ReadingMemo) async { await memoFeature.deleteReadingMemo(memo) }
}
