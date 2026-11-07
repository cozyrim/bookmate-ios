import Foundation

@MainActor
protocol BestsellerRepository {
    func fetchRealtime() async throws -> BestsellerFeed
}
