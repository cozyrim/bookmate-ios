//
//  TokenRefreshCoordinator.swift
//  BookMate
//
//  Expired access-token recovery shared by all authenticated API requests.
//

import Foundation

actor TokenRefreshCoordinator {
    static let shared = TokenRefreshCoordinator()

    private var refreshTask: Task<String, Error>?

    /// Shares one refresh request across concurrent 401 responses and avoids a
    /// second refresh when another request already replaced the access token.
    func accessToken(afterUnauthorizedRequestWith failedAccessToken: String) async throws -> String {
        let tokenStore = KeychainTokenStore()

        if let currentAccessToken = tokenStore.load(), currentAccessToken != failedAccessToken {
            return currentAccessToken
        }

        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task {
            try await TokenRefreshService().refreshAccessToken()
        }
        refreshTask = task

        do {
            let refreshedAccessToken = try await task.value
            refreshTask = nil
            return refreshedAccessToken
        } catch {
            refreshTask = nil
            throw error
        }
    }
}

private struct TokenRefreshService {
    private let baseURL = APIEnvironment.baseURL
    private let tokenStore: AuthTokenStore = KeychainTokenStore()

    private struct RefreshBody: Encodable {
        let refreshToken: String
    }

    func refreshAccessToken() async throws -> String {
        guard let refreshToken = tokenStore.loadRefreshToken() else {
            throw APIError.unauthorized
        }

        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("auth")
            .appendingPathComponent("refresh")

        var request = URLRequest(url: url, timeoutInterval: APIClient.defaultTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RefreshBody(refreshToken: refreshToken))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if (400..<500).contains(httpResponse.statusCode) {
                throw APIError.unauthorized
            }

            throw APIError.serverStatusCode(httpResponse.statusCode, nil)
        }

        let refreshedTokens: TokenRefreshResponse
        do {
            refreshedTokens = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }

        tokenStore.save(
            accessToken: refreshedTokens.accessToken,
            refreshToken: refreshedTokens.refreshToken
        )

        return refreshedTokens.accessToken
    }
}
