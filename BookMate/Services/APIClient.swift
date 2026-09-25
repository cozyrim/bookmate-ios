//
//  APIClient.swift
//  BookMate
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

/// 모든 API 서비스에서 공통으로 사용하는 네트워크 헬퍼
/// - makeRequest: Keychain 토큰을 Authorization 헤더에 자동으로 실어주는 URLRequest 생성
/// - validate: 서버 응답 상태 코드 검증
struct APIClient {
    static let defaultTimeoutInterval: TimeInterval = 12

    private let tokenStore: AuthTokenStore = KeychainTokenStore()

    /// Authorization 헤더가 포함된 URLRequest를 만들어요.
    func makeRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = makeUnauthenticatedRequest(url: url, method: method)

        if let token = tokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func makeRequest(url: URL, method: String = "GET", accessToken: String?) -> URLRequest {
        var request = makeUnauthenticatedRequest(url: url, method: method)

        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else if let token = tokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func makeUnauthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: Self.defaultTimeoutInterval)
        request.httpMethod = method

        return request
    }

    /// Executes an API request and retries it once after refreshing an expired access token.
    /// Requests without an Authorization header are sent unchanged.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let generation = KeychainTokenStore.sessionGeneration
        let initialResult = try await URLSession.shared.data(for: request)
        if bearerToken(in: request) != nil, generation != KeychainTokenStore.sessionGeneration {
            throw CancellationError()
        }

        guard isUnauthorized(initialResult.1),
              let failedAccessToken = bearerToken(in: request) else {
            return initialResult
        }

        let refreshedAccessToken = try await TokenRefreshCoordinator.shared
            .accessToken(afterUnauthorizedRequestWith: failedAccessToken)

        guard generation == KeychainTokenStore.sessionGeneration else { throw CancellationError() }
        var retryRequest = request
        retryRequest.setValue("Bearer \(refreshedAccessToken)", forHTTPHeaderField: "Authorization")
        let result = try await URLSession.shared.data(for: retryRequest)
        guard generation == KeychainTokenStore.sessionGeneration else { throw CancellationError() }
        return result
    }

    /// 서버 응답 상태 코드를 검증해요.
    /// - 401: APIError.unauthorized
    /// - 2xx 이외: APIError.badStatusCode
    func validate(
        _ response: URLResponse,
        data: Data? = nil,
        treatsUnauthorizedAsExpiredSession: Bool = true
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            if !treatsUnauthorizedAsExpiredSession {
                throw APIError.serverStatusCode(httpResponse.statusCode, errorMessage(from: data))
            }

            throw APIError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let data {
                throw APIError.serverStatusCode(httpResponse.statusCode, errorMessage(from: data))
            }

            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }

    private func errorMessage(from data: Data?) -> String? {
        guard let data, !data.isEmpty else {
            return nil
        }

        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return object["message"] as? String
            ?? object["error"] as? String
    }

    private func isUnauthorized(_ response: URLResponse) -> Bool {
        (response as? HTTPURLResponse)?.statusCode == 401
    }

    private func bearerToken(in request: URLRequest) -> String? {
        guard let authorization = request.value(forHTTPHeaderField: "Authorization"),
              authorization.hasPrefix("Bearer ") else {
            return nil
        }

        let token = String(authorization.dropFirst("Bearer ".count)).trimmingCharacters(in: .whitespaces)
        return token.isEmpty ? nil : token
    }
}
