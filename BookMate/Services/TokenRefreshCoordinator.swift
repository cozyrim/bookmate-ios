import Foundation

@MainActor
final class TokenRefreshCoordinator {
    static let shared = TokenRefreshCoordinator()
    private var refreshTask: (id: UUID, credential: String, task: Task<String, Error>)?

    func accessToken(afterUnauthorizedRequestWith failedAccessToken: String) async throws -> String {
        let store = KeychainTokenStore()
        guard let current = store.load() else { throw CancellationError() }
        if current != failedAccessToken { return current }
        guard let credential = store.loadRefreshToken() else { throw APIError.unauthorized }
        if let pending = refreshTask, pending.credential == credential {
            return try await pending.task.value
        }
        let id = UUID()
        let task = Task { try await TokenRefreshService().refreshAccessToken(expectedRefreshToken: credential) }
        refreshTask = (id, credential, task)
        defer {
            if refreshTask?.id == id { refreshTask = nil }
        }
        return try await task.value
    }
}

@MainActor
struct TokenRefreshService {
    var baseURL = APIEnvironment.baseURL
    var tokenStore: AuthTokenStore = KeychainTokenStore()
    var session: URLSession = .shared

    func refreshAccessToken(expectedRefreshToken: String) async throws -> String {
        let url = baseURL.appendingPathComponent("api/auth/refresh")
        var request = URLRequest(url: url, timeoutInterval: APIClient.defaultTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refreshToken": expectedRefreshToken])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            guard tokenStore.loadRefreshToken() == expectedRefreshToken else { throw CancellationError() }
            if http.statusCode == 401 { throw APIError.unauthorized }
            throw APIError.serverStatusCode(http.statusCode, nil)
        }
        let tokens: TokenRefreshResponse
        do { tokens = try JSONDecoder().decode(TokenRefreshResponse.self, from: data) }
        catch { throw APIError.invalidResponse }
        guard tokenStore.replace(expectedRefreshToken: expectedRefreshToken,
                                 accessToken: tokens.accessToken, refreshToken: tokens.refreshToken) else {
            // Logout may have raced a rotation. Revoke only the discarded credential.
            try? await AuthAPIService().logout(refreshToken: tokens.refreshToken, baseURL: baseURL, session: session)
            throw CancellationError()
        }
        return tokens.accessToken
    }
}
