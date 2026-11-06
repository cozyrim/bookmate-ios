import Foundation

protocol ReviewRepository {
    func fetchMyReview(bookId: UUID) async throws -> Review?
    func saveReview(
        bookId: UUID,
        rating: Int,
        content: String,
        isPublic: Bool
        ) async throws -> Review
    func fetchPublicReviews(
        isbn: String,
        title: String,
        author: String
        ) async throws -> [Review]
}
