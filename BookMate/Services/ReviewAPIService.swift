//
//  ReviewAPIService.swift
//  BookMate
//
//  Created by 한채림 on 6/13/26.
//

import Foundation

private struct ReviewSaveRequest: Encodable {
    let rating: Int
    let content: String
    let isPublic: Bool
}

private struct ReviewResponse: Decodable {
    let id: UUID
    let ownerId: UUID
    let ownerNickname: String
    let ownerProfileImageUrl: String?
    let bookId: UUID
    let rating: Int
    let content: String
    let isPublic: Bool
    let createdAt: String
    let updatedAt: String

    func toReview() -> Review {
        Review(
            id: id,
            ownerId: ownerId,
            ownerNickname: ownerNickname,
            ownerProfileImageURL: ownerProfileImageUrl,
            bookId: bookId,
            rating: rating,
            content: content,
            isPublic: isPublic,
            createdAt: BookMateDateFormatter.serverDateTime(from: createdAt) ?? Date(),
            updatedAt: BookMateDateFormatter.serverDateTime(from: updatedAt) ?? Date()
        )
    }
}

struct ReviewAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient()

    func fetchMyReview(bookId: UUID) async throws -> Review? {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(bookId.uuidString)
            .appendingPathComponent("reviews")
            .appendingPathComponent("me")

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 204 {
            return nil
        }

        let reviewResponse = try JSONDecoder().decode(ReviewResponse.self, from: data)
        return reviewResponse.toReview()
    }

    func saveReview(
        bookId: UUID,
        rating: Int,
        content: String,
        isPublic: Bool
    ) async throws -> Review {
        let url = baseURL
            .appendingPathComponent("api/books/\(bookId.uuidString)/reviews/me")

        let body = ReviewSaveRequest(rating: rating, content: content, isPublic: isPublic)

        var request = client.makeRequest(url: url, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let reviewResponse = try JSONDecoder().decode(ReviewResponse.self, from: data)
        return reviewResponse.toReview()
    }

    func fetchPublicReviews(
        isbn: String,
        title: String,
        author: String
    ) async throws -> [Review] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("reviews")
            .appendingPathComponent("public")

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "isbn", value: isbn),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "author", value: author)
        ]

        let request = client.makeRequest(url: components.url!)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let reviewResponses = try JSONDecoder().decode([ReviewResponse].self, from: data)
        return reviewResponses.map { $0.toReview() }
    }


}
