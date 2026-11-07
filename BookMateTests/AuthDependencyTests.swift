import XCTest
@testable import BookMate

@MainActor
final class AuthDependencyTests: XCTestCase {
    func testRestoreWithoutStoredTokenDoesNotCallServer() async {
        let repository = AuthRepositoryStub()
        let tokens = AuthMemoryTokens()
        let model = AuthSessionViewModel(dependencies: AppDependencies(auth: repository, tokens: tokens, pushTokens: PushTokenStub()), restoreSessionOnInit: false)

        await model.restoreSession()

        XCTAssertEqual(repository.profileRequests, 0)
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertFalse(model.isCheckingSession)
    }

    func testRestoredSessionLeavesLaunchScreenBeforePushSync() async {
        let repository = AuthRepositoryStub()
        let tokens = AuthMemoryTokens()
        tokens.save("stored-access")
        repository.profileResponse = ProfileResponse(id: UUID(), email: "reader@example.invalid", provider: "LOCAL", nickname: "독서가", profileImageUrl: nil, createdAt: nil, togetherDays: 1, savedWordCount: 0, readBookCount: 0, isPublic: true, roomTheme: nil)
        let push = PushTokenStub()
        let model = AuthSessionViewModel(dependencies: AppDependencies(auth: repository, tokens: tokens, pushTokens: push), restoreSessionOnInit: false)
        model.isCheckingSession = true
        push.onSync = {
            XCTAssertTrue(model.isLoggedIn)
            XCTAssertFalse(model.isCheckingSession, "Push synchronization must not keep the launch screen visible")
        }
        await model.restoreSession()
        XCTAssertEqual(push.syncCount, 1)
    }

    func testEmailLoginSavesReturnedTokensAndLoadsProfile() async {
        let repository = AuthRepositoryStub()
        let tokens = AuthMemoryTokens()
        let push = PushTokenStub()
        let user = AuthUser(id: UUID(), email: "reader@example.invalid", provider: "LOCAL", nickname: "사용자", profileImageUrl: nil, createdAt: nil, isPublic: true, roomTheme: nil)
        repository.loginResponse = AuthResponse(accessToken: "test-access", refreshToken: "test-refresh", tokenType: "Bearer", user: user)
        repository.profileResponse = ProfileResponse(id: user.id, email: user.email, provider: user.provider, nickname: user.nickname, profileImageUrl: nil, createdAt: nil, togetherDays: 1, savedWordCount: 0, readBookCount: 0, isPublic: true, roomTheme: nil)
        let model = AuthSessionViewModel(dependencies: AppDependencies(auth: repository, tokens: tokens, pushTokens: push), restoreSessionOnInit: false)

        await model.login(email: "reader@example.invalid", password: "test-password")

        XCTAssertEqual(tokens.load(), "test-access")
        XCTAssertEqual(tokens.loadRefreshToken(), "test-refresh")
        XCTAssertEqual(model.currentUser?.id, user.id)
        XCTAssertEqual(model.profile?.id, user.id)
        XCTAssertTrue(model.isLoggedIn)
        XCTAssertFalse(model.isLoading)
        XCTAssertEqual(push.syncCount, 1)
    }

    func testLoginFailureDoesNotOverwriteStoredCredentials() async {
        let repository = AuthRepositoryStub()
        let tokens = AuthMemoryTokens()
        tokens.save(accessToken: "existing-access", refreshToken: "existing-refresh")
        let push = PushTokenStub()
        let model = AuthSessionViewModel(dependencies: AppDependencies(auth: repository, tokens: tokens, pushTokens: push), restoreSessionOnInit: false)

        await model.login(email: "reader@example.invalid", password: "incorrect")

        XCTAssertEqual(tokens.load(), "existing-access")
        XCTAssertEqual(tokens.loadRefreshToken(), "existing-refresh")
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertFalse(model.isLoading)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(push.syncCount, 0)
    }

    func testUnauthorizedRestoreClearsInjectedCredentials() async {
        let repository = AuthRepositoryStub()
        repository.profileError = APIError.unauthorized
        let tokens = AuthMemoryTokens()
        tokens.save(accessToken: "expired", refreshToken: "refresh")
        let model = AuthSessionViewModel(dependencies: AppDependencies(auth: repository, tokens: tokens, pushTokens: PushTokenStub()), restoreSessionOnInit: false)

        await model.restoreSession()

        XCTAssertNil(tokens.load())
        XCTAssertNil(tokens.loadRefreshToken())
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertFalse(model.isCheckingSession)
    }
}

@MainActor
private final class AuthMemoryTokens: AuthTokenStore {
    private var access: String?
    private var refresh: String?
    func save(_ token: String) { access = token; refresh = nil }
    func save(accessToken: String, refreshToken: String) { access = accessToken; refresh = refreshToken }
    func load() -> String? { access }
    func loadRefreshToken() -> String? { refresh }
    func clear() { access = nil; refresh = nil }
    func replace(expectedRefreshToken: String, accessToken: String, refreshToken: String) -> Bool {
        guard refresh == expectedRefreshToken else { return false }
        save(accessToken: accessToken, refreshToken: refreshToken)
        return true
    }
}

@MainActor
private final class PushTokenStub: PushTokenManaging {
    var syncCount = 0
    var onSync: (() -> Void)?
    func syncTokenWithServerIfPossible(forceRefreshToken: Bool) async { syncCount += 1; onSync?() }
    func disableCurrentTokenOnServer(accessToken: String?) async {}
}

private enum AuthStubError: Error { case rejected }

@MainActor
private final class AuthRepositoryStub: AuthRepository {
    var loginResponse: AuthResponse?
    var profileResponse: ProfileResponse?
    var profileError: Error = AuthStubError.rejected
    var profileRequests = 0
    func login(email: String, password: String) async throws -> AuthResponse { guard let loginResponse else { throw AuthStubError.rejected }; return loginResponse }
    func loginWithKakao(accessToken: String) async throws -> AuthResponse { throw AuthStubError.rejected }
    func loginWithApple(credentials: AppleLoginCredentials) async throws -> AuthResponse { throw AuthStubError.rejected }
    func signup(email: String, password: String, nickname: String) async throws -> AuthResponse { throw AuthStubError.rejected }
    func fetchNicknameSuggestion() async throws -> String { throw AuthStubError.rejected }
    func checkEmailAvailability(email: String) async throws -> EmailAvailabilityResponse { throw AuthStubError.rejected }
    func checkNicknameAvailability(nickname: String) async throws -> NicknameAvailabilityResponse { throw AuthStubError.rejected }
    func fetchProfile(token: String) async throws -> ProfileResponse { profileRequests += 1; guard let profileResponse else { throw profileError }; return profileResponse }
    func updateProfile(
            token: String,
            nickname: String,
            profileImageUrl: String?,
            isPublic: Bool,
            roomTheme: String
        ) async throws -> ProfileResponse { throw AuthStubError.rejected }
    func logout(refreshToken: String, baseURL: URL,
                    session: URLSession) async throws { throw AuthStubError.rejected }
    func withdraw(token: String) async throws { throw AuthStubError.rejected }
    func uploadProfileImage(
            token: String,
            imageData: Data,
            fileName: String,
            mimeType: String
        ) async throws -> String { throw AuthStubError.rejected }
}
