import Foundation

protocol BookPageRepository {
    func fetchPageCount(isbn: String) async -> Int?
}
