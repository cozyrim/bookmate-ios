//
//  WordAPIService.swift
//  BookMate
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

struct WordAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient() // ← 공통 네트워크 헬퍼

    // 서버에서 전체 저장 단어 목록 가져오기
    // GET /api/words
    func fetchWords() async throws -> [Word] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("words")

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

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

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

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

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let wordResponse = try JSONDecoder().decode(WordResponse.self, from: data)
        return wordResponse.toWord()
    }

    // 서버에 단어 수정하기
    // PATCH /api/words/{wordId}
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

        var request = client.makeRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        let wordResponse = try JSONDecoder().decode(WordResponse.self, from: data)
        return wordResponse.toWord()
    }

    // 서버에 단어 삭제하기
    // DELETE /api/words/{wordId}
    func deleteWord(id: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("words")
            .appendingPathComponent(id.uuidString)

        let request = client.makeRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)
    }
}
