//
//  SocialAPIService.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/10/26.
//

import Foundation

struct SocialAPIService {
    private let baseURL = URL(string: "http://127.0.0.1:8080")!
    private let client = APIClient()
    
    // 1. 유저 검색 API
        func searchUsers(token: String, nickname: String) async throws -> [PublicUserResponse] {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
            components.path = "/api/social/users/search"
            components.queryItems = [URLQueryItem(name: "nickname", value: nickname)]
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
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
            
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
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
                
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
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
                
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
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
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
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
                
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            try client.validate(response)
        }
}
