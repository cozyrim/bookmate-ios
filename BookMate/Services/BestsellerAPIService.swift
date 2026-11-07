import Foundation

struct BestsellerAPIService: BestsellerRepository {
    private let client = APIClient()

    func fetchRealtime() async throws -> BestsellerFeed {
        let url = APIEnvironment.baseURL.appendingPathComponent("api/discovery/bestsellers/realtime")
        var request = client.makeUnauthenticatedRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await client.data(for: request)
        try client.validate(response, data: data, treatsUnauthorizedAsExpiredSession: false)
        return try JSONDecoder().decode(BestsellerFeed.self, from: data)
    }
}
