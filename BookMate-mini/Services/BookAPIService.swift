//
//  BookAPIService.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/21/26.
//

import Foundation

private struct BookCreateRequest: Encodable {
    let title: String
    let author: String
    let imageName: String
    let category: String
    let progress: Double
    let totalPages: Int?
    let currentPage: Int?
    let isbn: String?
}

private struct BookUpdateRequest: Encodable {
    let title: String
    let author: String
    let imageName: String
    let category: String
    let progress: Double
    let totalPages: Int?
    let currentPage: Int?
    let rating: Int?
    let review: String?
    let readingStatus: String?   // 서버에 전송할 때는 rawValue(String)으로
    let startDate: String?
    let endDate: String?
}

private struct BookResponse: Decodable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let category: String?
    let progress: Double
    let createdAt: String?
    let totalPages: Int?
    let currentPage: Int?
    let rating: Int?
    let review: String?
    let readingStatus: String?   // 서버는 String으로 내려줌
    let startDate: String?
    let endDate: String?

    func toBook() -> Book {
        Book(
            id: id,
            title: title,
            author: author,
            imageName: imageName,
            category: category ?? "카테고리 선택",
            progress: progress,
            totalPages: totalPages,
            currentPage: currentPage,
            rating: rating,
            review: review,
            readingStatus: readingStatus.flatMap { ReadingStatus(rawValue: $0) },
            startDate: startDate,
            endDate: endDate
        )
    }
}

// (Book 저장/수정할 때만 쓰는 에러)
enum BookAPIError: Error {
    case invalidRequestBody
}

struct BookAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient() // ← 공통 네트워크 헬퍼

    // 서버에서 전체 책 목록 가져오기
    // GET /api/books
    func fetchBooks() async throws -> [Book] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let bookResponse = try JSONDecoder().decode([BookResponse].self, from: data)
        return bookResponse.map { $0.toBook() }
    }

    // 서버에서 책 하나 가져오기
    // GET /api/books/{bookId}
    func fetchBook(id: UUID) async throws -> Book {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(id.uuidString)

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
        return bookResponse.toBook()
    }

    // 서버에 새 책 등록하기
    // POST /api/books
    func createBook(
        title: String,
        author: String,
        imageName: String,
        category: String = "카테고리 선택",
        progress: Double,
        totalPages: Int? = nil,
        currentPage: Int? = nil,
        isbn: String? = nil,
    ) async throws -> Book {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")

        let requestBody = BookCreateRequest(
            title: title,
            author: author,
            imageName: imageName,
            category: category,
            progress: progress,
            totalPages: totalPages,
            currentPage: currentPage,
            isbn: isbn,
        )

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
        return bookResponse.toBook()
    }

    func updateBook(_ book: Book) async throws -> Book {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(book.id.uuidString)

        let safeTitle = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeAuthor = book.author.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeImageName = book.imageName.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeCategory = book.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "카테고리 선택"
            : book.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeProgress = book.progress.isFinite ? book.progress : 0.0

        guard !safeTitle.isEmpty,
              !safeAuthor.isEmpty,
              !safeImageName.isEmpty else {
            throw BookAPIError.invalidRequestBody
        }

        let requestBody = BookUpdateRequest(
            title: safeTitle,
            author: safeAuthor,
            imageName: safeImageName,
            category: safeCategory,
            progress: safeProgress,
            totalPages: book.totalPages,
            currentPage: book.currentPage,
            rating: book.rating,
            review: book.review,
            readingStatus: book.readingStatus?.rawValue,
            startDate: book.startDate,
            endDate: book.endDate
        )

        var request = client.makeRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
        return bookResponse.toBook()
    }

    // 서버에 책 삭제하기
    // DELETE /api/books/{bookId}
    func deleteBook(id: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(id.uuidString)

        let request = client.makeRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)
    }
}
