//
//  SocialAPIService.swift
//  BookMate
//
//  Created by 한채림 on 6/10/26.
//

import Foundation

struct SocialAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient()
    
    // 1. 유저 검색 API
        func searchUsers(token: String, nickname: String) async throws -> [PublicUserResponse] {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
            components.path = "/api/social/users/search"
            components.queryItems = [URLQueryItem(name: "nickname", value: nickname)]
            
            let request = client.makeRequest(url: components.url!, method: "GET", accessToken: token)
            
            let (data, response) = try await client.data(for: request)
            try client.validate(response)
            
            return try JSONDecoder().decode([PublicUserResponse].self, from: data)
        }
        
    // 랜덤 유저 가져오기 API (파도타기용)
    func getRandomUser(token: String) async throws -> PublicUserResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("social")
            .appendingPathComponent("users")
            .appendingPathComponent("random")
            
        let request = client.makeRequest(url: url, method: "GET", accessToken: token)
        
        let (data, response) = try await client.data(for: request)
        try client.validate(response)
        
        return try JSONDecoder().decode(PublicUserResponse.self, from: data)
    }
    
    // 2. 다른 사람의 공개 책장(책 목록) 조회 API
        // (BookResponse는 이미 존재하므로 그대로 사용)
        func fetchPublicBooks(token: String, userId: UUID) async throws -> [Book] {
            let url = baseURL
                .appendingPathComponent("api")
                .appendingPathComponent("social")
                .appendingPathComponent("users")
                .appendingPathComponent(userId.uuidString)
                .appendingPathComponent("books")
                
            let request = client.makeRequest(url: url, method: "GET", accessToken: token)
            
            let (data, response) = try await client.data(for: request)
            try client.validate(response)
            
            let bookResponses = try JSONDecoder().decode([PublicBookResponse].self, from: data)
            return bookResponses.map { $0.toBook() }
        }
    
    // MARK: - 방명록 (Guestbook) API
    
    // 1. 특정 유저의 방명록 리스트 가져오기
        func fetchGuestbook(token: String, userId: UUID) async throws -> [GuestbookMessageResponse] {
            let url = baseURL
                .appendingPathComponent("api")
                .appendingPathComponent("social")
                .appendingPathComponent("users")
                .appendingPathComponent(userId.uuidString)
                .appendingPathComponent("guestbook")
                
            let request = client.makeRequest(url: url, method: "GET", accessToken: token)
            
            let (data, response) = try await client.data(for: request)
            try client.validate(response)
            
            return try JSONDecoder().decode([GuestbookMessageResponse].self, from: data)
        }
        
        // 2. 다른 사람 책장에 방명록 쓰기
        func writeGuestbook(token: String, userId: UUID, content: String) async throws -> GuestbookMessageResponse {
            let url = baseURL
                .appendingPathComponent("api")
                .appendingPathComponent("social")
                .appendingPathComponent("users")
                .appendingPathComponent(userId.uuidString)
                .appendingPathComponent("guestbook")
                
            let requestBody = GuestbookWriteRequest(content: content)
            
            var request = client.makeRequest(url: url, method: "POST", accessToken: token)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await client.data(for: request)
            try client.validate(response)
            
            return try JSONDecoder().decode(GuestbookMessageResponse.self, from: data)
        }
        
        // 3. 내 방명록 지우기 (또는 내가 남긴 방명록 지우기)
        func deleteGuestbook(token: String, messageId: UUID) async throws {
            let url = baseURL
                .appendingPathComponent("api")
                .appendingPathComponent("social")
                .appendingPathComponent("guestbook")
                .appendingPathComponent(messageId.uuidString)
                
            let request = client.makeRequest(url: url, method: "DELETE", accessToken: token)
            
            let (_, response) = try await client.data(for: request)
            try client.validate(response)
        }
}
