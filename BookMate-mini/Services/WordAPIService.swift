//
//  WordAPIService.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/20/26.
//

import Foundation

private struct WordCreateRequest: Encodable {
    let bookId: UUID
    let text: String
    let meaning: String
    let partOfSpeech: String
    let exampleSentence: String?
    let targetCode: String
}

private struct WordUpdateRequest: Encodable {
    let bookId: UUID
    let text: String
    let meaning: String
    let partOfSpeech: String
    let exampleSentence: String?
    let targetCode: String
}


private struct WordResponse: Decodable {
    let id: UUID
    let bookId: UUID
    let text: String
    let meaning: String
    let partOfSpeech: String?
    let exampleSentence: String?
    let createdAt: String?
    let targetCode: String?

    func toWord() -> Word {
        Word(
            id: id,
            text: text,
            meaning: meaning,
            partOfSpeech: partOfSpeech ?? "",
            exampleSentence: exampleSentence,
            targetCode: targetCode ?? "",
            bookId: bookId
        )
    }
}

enum WordAPIError: Error {
    case invalidResponse
    case unauthorized
    case badStatusCode(Int)
}

private let tokenStore: AuthTokenStore = KeychainTokenStore()

private func makeRequest(url: URL, method: String = "GET") -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method

    if let token = tokenStore.load() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    return request
}



struct WordAPIService {
    private let baseURL = URL(string: "http://127.0.0.1:8080")!

    // 서버에서 전체 저장 단어 목록 가져오기
    // GET /api/words
    func fetchWords() async throws -> [Word] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("words")

        let request = makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        try validate(response)

        let wordResponses = try JSONDecoder().decode([WordResponse].self, from: data)
        return wordResponses.map { $0.toWord() }
    }


    // 특정 책에 저장된 단어만 가져오기
    // GET /api/books/{bookId}/words
    func fetchWords(bookId: UUID) async throws -> [Word] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("books")
            .appendingPathComponent(bookId.uuidString)
            .appendingPathComponent("words")

        let request = makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        try validate(response)

        let wordResponses = try JSONDecoder().decode([WordResponse].self, from: data)
        return wordResponses.map { $0.toWord() }
    }

    // 서버에 단어 저장하기
    // POST /api/words
    func saveWord(
        bookId: UUID,
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String
    ) async throws -> Word {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("words")

        let requestBody = WordCreateRequest(
            bookId: bookId,
            text: text,
            meaning: meaning,
            partOfSpeech: partOfSpeech,
            exampleSentence: exampleSentence,
            targetCode: targetCode
        )

        var request = makeRequest(url: url, method: "POST")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        try validate(response)

        let wordResponse = try JSONDecoder().decode(WordResponse.self, from: data)
        return wordResponse.toWord()
    }

    // 서버에 단어 수정하기
    func updateWord(_ word: Word) async throws -> Word {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("words")
            .appendingPathComponent(word.id.uuidString)

        let requestBody = WordUpdateRequest(
            bookId: word.bookId,
            text: word.text,
            meaning: word.meaning,
            partOfSpeech: word.partOfSpeech,
            exampleSentence: word.exampleSentence,
            targetCode: word.targetCode
        )

        var request = makeRequest(url: url, method: "PATCH")
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)

        let wordResponse = try JSONDecoder().decode(WordResponse.self, from: data)
        return wordResponse.toWord()
    }

    // 서버에 단어 삭제하기
    func deleteWord(id: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("words")
            .appendingPathComponent(id.uuidString)

        var request = makeRequest(url: url, method: "DELETE")
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)

    }






    // 서버 응답이 성공인지 확인하기
    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WordAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw WordAPIError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw WordAPIError.badStatusCode(httpResponse.statusCode)
        }
    }
}
