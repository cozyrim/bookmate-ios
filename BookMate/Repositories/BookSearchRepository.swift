import Foundation

protocol BookSearchRepository {
    func searchBooks(query: String) async throws -> [KakaoBook]
}
