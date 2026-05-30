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
}

private struct BookUpdateRequest: Encodable {
    let title: String
    let author: String
    let imageName: String
    let category: String
    let progress: Double
}

private struct BookResponse: Decodable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let category: String?
    let progress: Double
    let createdAt: String?
    
    func toBook() -> Book {
        Book(
            id: id,
            title: title,
            author: author,
            imageName: imageName,
            category: category ?? "카테고리 선택",
            progress: progress
        )
    }
}

enum BookAPIError: Error {
    case invalidResponse
    case badStatusCode(Int)
    case invalidRequestBody
}

struct BookAPIService {
    private let baseURL = URL(string: "http://localhost:8080")!

    
    // 서버에서 전체 책 목록 가져오기
    // GET /api/books
    func fetchBooks() async throws -> [Book] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        try validate(response)
        
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
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        try validate(response)
        
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
        progress: Double
    ) async throws -> Book {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
        
        let requestBody = BookCreateRequest( // swift에서 서버로 보낼 json 모양
            title: title,
            author: author,
            imageName: imageName,
            category: category,
            progress: progress
        )
        
        var request = URLRequest(url : url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try validate(response)
        
        // 서버에서 swift로 받는 json 모양
        let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
        return bookResponse.toBook()
    }
    
    // 서버에 책 수정하기
    func updateBook(_ book: Book) async throws -> Book {
        let url = baseURL
                .appendingPathComponent("api")
                .appendingPathComponent("books")
                .appendingPathComponent(book.id.uuidString)

            let safeProgress = book.progress.isFinite ? book.progress : 0.0
            let safeCategory = book.category.isEmpty ? "카테고리 선택" : book.category

            let requestBody = BookUpdateRequest(
                title: book.title,
                author: book.author,
                imageName: book.imageName,
                category: safeCategory,
                progress: safeProgress
            )

            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response)

            let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
            return bookResponse.toBook()
        }
    
    // 서버에 책 삭제하기
    func deleteBook(id: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(id.uuidString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }
    
    
    
    
    
    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BookAPIError.badStatusCode(httpResponse.statusCode)
        }
    }
}
