//
//  ReadingMemoAPIService.swift
//  BookMate
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

private struct ReadingMemoCreateRequest: Encodable {
    let bookId: UUID
    let date: String
    let page: Int?
    let text: String
}

private struct ReadingMemoUpdateRequest: Encodable {
    let date: String
    let page: Int?
    let text: String
}

private struct ReadingMemoResponse: Decodable {
    let id: UUID
    let bookId: UUID
    let date: String
    let page: Int?
    let text: String
    let createdAt: String? // 서버에서 생성 시간 등을 내려줄 수 있음
    
    // 서버 데이터를 앱의 모델 구조체로 예쁘게 변환해 주는 함수
    func toReadingMemo() -> ReadingMemo {
        ReadingMemo(
            id: id,
            bookId: bookId,
            date: date,
            page: page,
            text: text
        )
    }
}

struct ReadingMemoAPIService {
    private let baseURL = APIEnvironment.baseURL
        private let client = APIClient()
    
    // 특정 책의 독서 메모 목록 가져오기
        func fetchMemos(bookId: UUID) async throws -> [ReadingMemo] {
            var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api/reading-memos"), resolvingAgainstBaseURL: false)! // query parameter 방식, 주소 뒤에 ?를 붙이고 검색 조건을 달아줌
            urlComponents.queryItems = [URLQueryItem(name: "bookId", value: bookId.uuidString)]
            
            let request = client.makeRequest(url: urlComponents.url!)
            let (data, response) = try await URLSession.shared.data(for: request)
            try client.validate(response)
            
            let memoResponses = try JSONDecoder().decode([ReadingMemoResponse].self, from: data)
                    return memoResponses.map { $0.toReadingMemo() }
        }
    
    // 독서 메모 저장하기
        func saveMemo(bookId: UUID, date: String, page: Int?, text: String) async throws -> ReadingMemo {
            let url = baseURL.appendingPathComponent("api/reading-memos")
            var request = client.makeRequest(url: url, method: "POST")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ReadingMemoCreateRequest(bookId: bookId, date: date, page: page, text: text)
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            try client.validate(response)
            
            let memoResponse = try JSONDecoder().decode(ReadingMemoResponse.self, from: data)
                    return memoResponse.toReadingMemo()
        }
    
    // 독서 메모 수정하기
        func updateMemo(_ memo: ReadingMemo) async throws -> ReadingMemo {
            let url = baseURL.appendingPathComponent("api/reading-memos/\(memo.id.uuidString)")
            var request = client.makeRequest(url: url, method: "PATCH")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ReadingMemoUpdateRequest(date: memo.date, page: memo.page, text: memo.text)
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            try client.validate(response)
            
            let memoResponse = try JSONDecoder().decode(ReadingMemoResponse.self, from: data)
                    return memoResponse.toReadingMemo()
        }
    
    // 독서 메모 삭제하기
        func deleteMemo(id: UUID) async throws {
            let url = baseURL.appendingPathComponent("api/reading-memos/\(id.uuidString)")
            let request = client.makeRequest(url: url, method: "DELETE")
            let (_, response) = try await URLSession.shared.data(for: request)
            try client.validate(response)
        }
}
