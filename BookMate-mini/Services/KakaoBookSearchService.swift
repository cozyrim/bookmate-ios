//
//  KakaoBookSearchService.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import Foundation

struct KakaoBookResponse: Decodable {
    let documents: [KakaoBook]
    let meta: KakaoBookMeta
}

struct KakaoBookMeta: Decodable {
    let isEnd: Bool
    let pageableCount: Int
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case isEnd = "is_end"
        case pageableCount = "pageable_count"
        case totalCount = "total_count"
    }
}

struct KakaoBook: Decodable, Identifiable {
    var id: String { isbn.isEmpty ? url : isbn }
    
    let title: String
    let contents: String
    let url: String
    let isbn: String
    let datetime: String
    let authors: [String]
    let publisher: String
    let thumbnail: String
}

enum KakaoBookSearchError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case badStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "카카오 REST API 키가 설정되어 있지 않습니다."
        case .invalidURL:
            return "책 검색 URL을 만들 수 없습니다."
        case .invalidResponse:
            return "카카오 책 검색 응답을 확인할 수 없습니다."
        case .badStatusCode(let statusCode):
            return "카카오 책 검색 요청에 실패했습니다. 상태 코드: \(statusCode)"
        }
    }
}

final class KakaoBookSearchService {
    private let apiKey: String
    private let session: URLSession

    init(
        apiKey: String = KakaoBookSearchService.defaultAPIKey,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.session = session
    }

    func searchBooks(query: String, page: Int = 1, size: Int = 20) async throws -> [KakaoBook] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return []
        }

        guard !apiKey.isEmpty else {
            throw KakaoBookSearchError.missingAPIKey
        }

        var components = URLComponents(string: "https://dapi.kakao.com/v3/search/book")
        components?.queryItems = [
            URLQueryItem(name: "query", value: trimmedQuery),
            URLQueryItem(name: "sort", value: "accuracy"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]

        guard let url = components?.url else {
            throw KakaoBookSearchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KakaoBookSearchError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw KakaoBookSearchError.badStatusCode(httpResponse.statusCode)
        }

        let decodedResponse = try JSONDecoder().decode(KakaoBookResponse.self, from: data)
        return decodedResponse.documents
    }

    private static var defaultAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String else {
            return ""
        }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "$(KAKAO_REST_API_KEY)" else {
            return ""
        }

        return trimmedKey
    }
}
