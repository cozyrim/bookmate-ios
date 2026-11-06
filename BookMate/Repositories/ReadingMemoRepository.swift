import Foundation

protocol ReadingMemoRepository {
    func fetchMemos(bookId: UUID) async throws -> [ReadingMemo]
    func saveMemo(bookId: UUID, date: String, page: Int?, text: String) async throws -> ReadingMemo
    func updateMemo(_ memo: ReadingMemo) async throws -> ReadingMemo
    func deleteMemo(id: UUID) async throws
}
