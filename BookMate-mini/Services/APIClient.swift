//
//  APIClient.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

/// 모든 API 서비스에서 공통으로 사용하는 네트워크 헬퍼
/// - makeRequest: Keychain 토큰을 Authorization 헤더에 자동으로 실어주는 URLRequest 생성
/// - validate: 서버 응답 상태 코드 검증
struct APIClient {
    private let tokenStore: AuthTokenStore = KeychainTokenStore()

    /// Authorization 헤더가 포함된 URLRequest를 만들어요.
    func makeRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = tokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    /// 서버 응답 상태 코드를 검증해요.
    /// - 401: APIError.unauthorized
    /// - 2xx 이외: APIError.badStatusCode
    func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }
}
