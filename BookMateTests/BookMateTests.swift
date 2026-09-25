import XCTest
@testable import BookMate

@MainActor
final class BookMateTests: XCTestCase {
    private func service(status: Int, body: String = "{}", store: MemoryTokenStore) -> TokenRefreshService {
        StubURLProtocol.status = status
        StubURLProtocol.body = Data(body.utf8)
        StubURLProtocol.logoutRequests = 0
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return TokenRefreshService(baseURL: URL(string: "https://example.invalid")!, tokenStore: store,
                                   session: URLSession(configuration: config))
    }

    func testRateLimitDoesNotBecomeSessionExpiry() async throws {
        let store = MemoryTokenStore()
        let api = service(status: 429, store: store)
        do {
            _ = try await api.refreshAccessToken(expectedRefreshToken: "old-refresh")
            XCTFail("Expected rate rejection")
        } catch APIError.serverStatusCode(let status, _) { XCTAssertEqual(status, 429) }
        catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertEqual(store.refresh, "old-refresh")
    }

    func testUnauthorizedRefreshStillExpiresSession() async throws {
        let api = service(status: 401, store: MemoryTokenStore())
        do {
            _ = try await api.refreshAccessToken(expectedRefreshToken: "old-refresh")
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized {} catch { XCTFail("Unexpected error: \(error)") }
    }

    func testLateRotationDoesNotRestoreLoggedOutSession() async throws {
        let store = MemoryTokenStore()
        store.beforeReplace = { store.clear() }
        let api = service(status: 200, body: """
        {"accessToken":"rotated-access","refreshToken":"rotated-refresh","tokenType":"Bearer"}
        """, store: store)
        do {
            _ = try await api.refreshAccessToken(expectedRefreshToken: "old-refresh")
            XCTFail("Expected cancelled session")
        } catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertNil(store.refresh)
        XCTAssertEqual(StubURLProtocol.logoutRequests, 1)
    }

    func testLateRotationDoesNotOverwriteNewLogin() async throws {
        let store = MemoryTokenStore()
        store.beforeReplace = { store.save(accessToken: "new-login", refreshToken: "new-login-refresh") }
        let api = service(status: 200, body: """
        {"accessToken":"rotated-access","refreshToken":"rotated-refresh","tokenType":"Bearer"}
        """, store: store)
        do {
            _ = try await api.refreshAccessToken(expectedRefreshToken: "old-refresh")
            XCTFail("Expected cancelled session")
        } catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertEqual(store.access, "new-login")
        XCTAssertEqual(store.refresh, "new-login-refresh")
        XCTAssertEqual(StubURLProtocol.logoutRequests, 1)
    }

    func testCurrentSessionAcceptsRotatedTokens() async throws {
        let store = MemoryTokenStore()
        let api = service(status: 200, body: """
        {"accessToken":"rotated-access","refreshToken":"rotated-refresh","tokenType":"Bearer"}
        """, store: store)
        let access = try await api.refreshAccessToken(expectedRefreshToken: "old-refresh")
        XCTAssertEqual(access, "rotated-access")
        XCTAssertEqual(store.refresh, "rotated-refresh")
        XCTAssertEqual(StubURLProtocol.logoutRequests, 0)
    }
}

@MainActor
private final class MemoryTokenStore: AuthTokenStore {
    var access: String? = "old-access"
    var refresh: String? = "old-refresh"
    var beforeReplace: (() -> Void)?
    func save(accessToken: String, refreshToken: String) { access = accessToken; refresh = refreshToken }
    func save(_ token: String) { access = token; refresh = nil }
    func load() -> String? { access }
    func loadRefreshToken() -> String? { refresh }
    func clear() { access = nil; refresh = nil }
    func replace(expectedRefreshToken: String, accessToken: String, refreshToken: String) -> Bool {
        beforeReplace?()
        guard refresh == expectedRefreshToken else { return false }
        save(accessToken: accessToken, refreshToken: refreshToken)
        return true
    }
}

private final class StubURLProtocol: URLProtocol {
    static var status = 200
    static var body = Data()
    static var logoutRequests = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let logout = request.url!.path.hasSuffix("/logout")
        if logout { Self.logoutRequests += 1 }
        let response = HTTPURLResponse(url: request.url!, statusCode: logout ? 204 : Self.status,
                                       httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: logout ? Data() : Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
