import Foundation

protocol DictionaryRepository {
    var isConfigured: Bool { get }
    func searchItems(query: String) async throws -> [StdDictItem]
}

struct StandardDictionaryRepository: DictionaryRepository {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String? = nil, session: URLSession = .shared) {
        let key = apiKey ?? Bundle.main.object(forInfoDictionaryKey: "STDICT_API_KEY") as? String ?? ""
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = trimmed == "$(STDICT_API_KEY)" ? "" : trimmed
        self.session = session
    }

    var isConfigured: Bool { !apiKey.isEmpty }

    func searchItems(query: String) async throws -> [StdDictItem] {
        var components = URLComponents(string: "https://stdict.korean.go.kr/api/search.do")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "req_type", value: "json")
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let request = URLRequest(url: url, timeoutInterval: APIClient.defaultTimeoutInterval)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(StdDictSearchResponse.self, from: data).channel.item
    }
}
