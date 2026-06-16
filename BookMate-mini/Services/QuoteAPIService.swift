//
//  QuoteAPIService.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

private struct QuoteCreateRequest: Encodable {
    let bookId: UUID
    let text: String
    let page: Int?
    let memo: String?
}

private struct QuoteUpdateRequest: Encodable {
    let bookId: UUID
    let text: String
    let page: Int?
    let memo: String?
}

private struct QuoteResponse: Decodable {
    let id: UUID
    let bookId: UUID
    let text: String
    let page: Int?
    let memo: String?
    let createdAt: String?

    func toQuote() -> Quote {
        Quote(
            id: id,
            text: text,
            page: page,
            memo: memo,
            bookId: bookId
        )
    }
}

struct QuoteAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient() // ← 공통 네트워크 헬퍼

    // 특정 책의 구절 목록 가져오기
    // GET /api/books/{bookId}/quotes
    func fetchQuotes(bookId: UUID) async throws -> [Quote] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(bookId.uuidString)
            .appendingPathComponent("quotes")

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let quoteResponses = try JSONDecoder().decode([QuoteResponse].self, from: data)
        return quoteResponses.map { $0.toQuote() }
    }

    // 구절 저장하기
    // POST /api/quotes
    func saveQuote(
        bookId: UUID,
        text: String,
        page: Int?,
        memo: String?
    ) async throws -> Quote {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("quotes")

        let requestBody = QuoteCreateRequest(
            bookId: bookId,
            text: text,
            page: page,
            memo: memo
        )

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let quoteResponse = try JSONDecoder().decode(QuoteResponse.self, from: data)
        return quoteResponse.toQuote()
    }

    // 구절 수정하기
    // PATCH /api/quotes/{quoteId}
    func updateQuote(_ quote: Quote) async throws -> Quote {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("quotes")
            .appendingPathComponent(quote.id.uuidString)

        let requestBody = QuoteUpdateRequest(
            bookId: quote.bookId,
            text: quote.text,
            page: quote.page,
            memo: quote.memo
        )

        var request = client.makeRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let quoteResponse = try JSONDecoder().decode(QuoteResponse.self, from: data)
        return quoteResponse.toQuote()
    }

    // 구절 삭제하기
    // DELETE /api/quotes/{quoteId}
    func deleteQuote(id: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("quotes")
            .appendingPathComponent(id.uuidString)

        let request = client.makeRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)
    }
}
