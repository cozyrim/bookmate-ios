import Foundation

protocol BookRepository {
    func fetchBooks() async throws -> [Book]
    func fetchBook(id: UUID) async throws -> Book
    func createBook(
        title: String,
        author: String,
        imageName: String,
        category: String,
        progress: Double,
        totalPages: Int?,
        currentPage: Int?,
        isbn: String?
    ) async throws -> Book
    func updateBook(_ book: Book) async throws -> Book
    func deleteBook(id: UUID) async throws
}
