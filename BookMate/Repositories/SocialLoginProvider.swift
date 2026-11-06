import AuthenticationServices

protocol KakaoLoginProviding {
    func login() async throws -> String
    func unlink() async throws
}

protocol AppleAuthorizationDecoding {
    func credentials(from authorization: ASAuthorization) throws -> AppleLoginCredentials
}

protocol PushTokenManaging {
    func syncTokenWithServerIfPossible(forceRefreshToken: Bool) async
    func disableCurrentTokenOnServer(accessToken: String?) async
}

extension PushTokenManaging {
    func syncTokenWithServerIfPossible() async {
        await syncTokenWithServerIfPossible(forceRefreshToken: false)
    }
}
