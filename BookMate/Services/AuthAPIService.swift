//
//  AuthAPIService.swift
//  BookMate
//
//  Created by 한채림 on 6/1/26.
//

import Foundation


struct AuthAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient() // ← 공통 네트워크 헬퍼
    
    private struct ProfileUpdateBody: Encodable {
        let nickname: String
        let profileImageUrl: String?
        let isPublic: Bool
        let roomTheme: String

        enum CodingKeys: String, CodingKey {
            case nickname
            case profileImageUrl
            case isPublic
            case roomTheme
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(nickname, forKey: .nickname)
            try container.encode(isPublic, forKey: .isPublic)
            try container.encode(roomTheme, forKey: .roomTheme)

            if let profileImageUrl {
                try container.encode(profileImageUrl, forKey: .profileImageUrl)
            } else {
                try container.encodeNil(forKey: .profileImageUrl)
            }
        }
    }
    
    private struct KakaoLoginBody: Encodable {
        let accessToken: String
    }

    private struct AppleLoginBody: Encodable {
        let identityToken: String
        let authorizationCode: String?
        let userIdentifier: String
        let email: String?
        let fullName: String?
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
        
        var request = client.makeUnauthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await client.data(for: request)
        
        try client.validate(response)
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func loginWithKakao(accessToken: String) async throws -> AuthResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("kakao")
        
        let body = KakaoLoginBody(accessToken: accessToken)
        
        var request = client.makeUnauthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await client.data(for: request)
        
        try client.validate(response)
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func loginWithApple(credentials: AppleLoginCredentials) async throws -> AuthResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("apple")

        let body = AppleLoginBody(
            identityToken: credentials.identityToken,
            authorizationCode: credentials.authorizationCode,
            userIdentifier: credentials.userIdentifier,
            email: credentials.email,
            fullName: credentials.fullName
        )

        var request = client.makeUnauthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await client.data(for: request)

        try client.validate(response, data: data, treatsUnauthorizedAsExpiredSession: false)

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
        
        var request = client.makeUnauthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await client.data(for: request)
        
        try client.validate(response)
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func fetchNicknameSuggestion() async throws -> String {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("nickname-suggestion")

        let request = client.makeUnauthenticatedRequest(url: url, method: "GET")

        let (data, response) = try await client.data(for: request)
        try client.validate(response)

        let suggestion = try JSONDecoder().decode(NicknameSuggestionResponse.self, from: data)
        return suggestion.nickname
    }

    func checkEmailAvailability(email: String) async throws -> EmailAvailabilityResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("email-availability")

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "email", value: email)
        ]

        let request = client.makeUnauthenticatedRequest(url: components.url!, method: "GET")

        let (data, response) = try await client.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode(EmailAvailabilityResponse.self, from: data)
    }

    func checkNicknameAvailability(nickname: String) async throws -> NicknameAvailabilityResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("nickname-availability")

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "nickname", value: nickname)
        ]

        let request = client.makeUnauthenticatedRequest(url: components.url!, method: "GET")

        let (data, response) = try await client.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode(NicknameAvailabilityResponse.self, from: data)
    }
    
    
    func fetchProfile(token: String) async throws -> ProfileResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("me")
        
        let request = client.makeRequest(url: url, method: "GET", accessToken: token)
        
        let (data, response) = try await client.data(for: request)
        
        try client.validate(response)
        
        return try JSONDecoder().decode(ProfileResponse.self, from: data)
    }
    
    func updateProfile(
        token: String,
        nickname: String,
        profileImageUrl: String?,
        isPublic: Bool,
        roomTheme: String
    ) async throws -> ProfileResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("me")

        
        let body = ProfileUpdateBody(nickname: nickname, profileImageUrl: profileImageUrl, isPublic: isPublic, roomTheme: roomTheme)
        
        var request = client.makeRequest(url: url, method: "PATCH", accessToken: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await client.data(for: request)
        
        try client.validate(response)
        
        return try JSONDecoder().decode(ProfileResponse.self, from: data)
    }
    
    // Use the captured refresh credential without the automatic refresh/retry path.
    func logout(refreshToken: String, baseURL: URL = APIEnvironment.baseURL,
                session: URLSession = .shared) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/auth/logout"),
                                 timeoutInterval: APIClient.defaultTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])
        let (_, response) = try await session.data(for: request)
        try client.validate(response, treatsUnauthorizedAsExpiredSession: false)
    }

    func withdraw(token: String) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("users")
            .appendingPathComponent("me")
        
        let request = client.makeRequest(url: url, method: "DELETE", accessToken: token)
        
        let (_, response) = try await client.data(for: request)
        
        try client.validate(response)
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
    
        var request = client.makeRequest(url: url, method: "POST", accessToken: token)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await client.data(for: request)
        
        try client.validate(response)
        
        let uploadResponse = try JSONDecoder().decode(ProfileImageUploadResponse.self, from: data)
        return uploadResponse.profileImageUrl
    }
    
}
