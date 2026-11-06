#if DEBUG
import Foundation

@MainActor
final class UIFixtureTokens: AuthTokenStore {
    private var access: String? = "fixture-access"
    private var refresh: String? = "fixture-refresh"
    func save(accessToken: String, refreshToken: String) { access = accessToken; refresh = refreshToken }
    func save(_ token: String) { access = token; refresh = nil }
    func load() -> String? { access }
    func loadRefreshToken() -> String? { refresh }
    func clear() { access = nil; refresh = nil }
    func replace(expectedRefreshToken: String, accessToken: String, refreshToken: String) -> Bool {
        guard refresh == expectedRefreshToken else { return false }
        save(accessToken: accessToken, refreshToken: refreshToken)
        return true
    }
}
#endif
