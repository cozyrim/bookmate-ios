//
//  AuthAPIService.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import Foundation


// signup, loginWithKakao, fetchProfile, updateProfile, logout를 추가하면 됨
struct AuthAPIService {
    private let baseURL = URL(string: "http://127.0.0.1:8080")!
    
    private struct ProfileUpdateBody: Encodable {
        let nickname: String
        let profileImageUrl: String?
    }
    
    private struct KakaoLoginBody: Encodable {
        let accessToken: String
    }
    
    
    
//    앱 재실행
//    → Keychain에 토큰 있음
//    → /api/me 요청
//    → 서버가 사용자 정보 줌
//    → 로그인 상태 유지 가능
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("login")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func loginWithKakao(accessToken: String) async throws -> AuthResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("kakao")
        
        let body = KakaoLoginBody(accessToken: accessToken)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("백엔드 카카오 로그인 status:", statusCode)
            print("백엔드 카카오 로그인 body:", String(data: data, encoding: .utf8) ?? "body 없음")

        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    
    
    func signup(email: String, password: String, nickname: String) async throws -> AuthResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("signup")
        
        let body = [
            "email": email,
            "password": password,
            "nickname": nickname
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    
    func fetchProfile(token: String) async throws -> ProfileResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("me")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(ProfileResponse.self, from: data)
    }
    
    func updateProfile(
        token: String,
        nickname: String,
        profileImageUrl: String?
    ) async throws -> ProfileResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("me")

        
        let body = ProfileUpdateBody(nickname: nickname, profileImageUrl: profileImageUrl)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("프로필 수정 status:", statusCode)
            print("프로필 수정 body:", String(data: data, encoding: .utf8) ?? "body 없음")
        
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(ProfileResponse.self, from: data)
    }
    
    func withdraw(token: String) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("users")
            .appendingPathComponent("me")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("회원 탈퇴 status:", statusCode)
            print("회원 탈퇴 body:", String(data: data, encoding: .utf8) ?? "body 없음")
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func uploadProfileImage(
        token: String,
        imageData: Data,
        fileName: String = "profile.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> String {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("me")
            .appendingPathComponent("profile-image")
        
        let boundary = "Boundary-\(UUID().uuidString)"
    
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let uploadResponse = try JSONDecoder().decode(ProfileImageUploadResponse.self, from: data)
        return uploadResponse.profileImageUrl
    }
    
    
    
    
}
