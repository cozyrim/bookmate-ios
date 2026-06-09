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
}
