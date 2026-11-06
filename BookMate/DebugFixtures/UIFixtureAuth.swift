#if DEBUG
import Foundation

@MainActor
final class UIFixtureAuth: AuthRepository {
    static let userID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    var profile = ProfileResponse(id: UIFixtureAuth.userID, email: "reader@example.invalid", provider: "LOCAL", nickname: "독서가", profileImageUrl: nil, createdAt: nil, togetherDays: 1, savedWordCount: 1, readBookCount: 1, isPublic: true, roomTheme: "room_bg_default")
    private var response: AuthResponse { AuthResponse(accessToken: "fixture-access", refreshToken: "fixture-refresh", tokenType: "Bearer", user: profile.toAuthUser()) }
    func login(email: String, password: String) async throws -> AuthResponse {
        return response
    }
    func loginWithKakao(accessToken: String) async throws -> AuthResponse {
        return response
    }
    func loginWithApple(credentials: AppleLoginCredentials) async throws -> AuthResponse {
        return response
    }
    func signup(email: String, password: String, nickname: String) async throws -> AuthResponse {
        return response
    }
    func fetchNicknameSuggestion() async throws -> String {
        return "독서가"
    }
    func checkEmailAvailability(email: String) async throws -> EmailAvailabilityResponse {
        return EmailAvailabilityResponse(email: email, available: true, message: "사용할 수 있어요.")
    }
    func checkNicknameAvailability(nickname: String) async throws -> NicknameAvailabilityResponse {
        return NicknameAvailabilityResponse(nickname: nickname, available: true, message: "사용할 수 있어요.")
    }
    func fetchProfile(token: String) async throws -> ProfileResponse {
        return profile
    }
    func updateProfile(
            token: String,
            nickname: String,
            profileImageUrl: String?,
            isPublic: Bool,
            roomTheme: String
        ) async throws -> ProfileResponse {
        profile = ProfileResponse(id: profile.id, email: profile.email, provider: profile.provider, nickname: nickname, profileImageUrl: profileImageUrl, createdAt: profile.createdAt, togetherDays: 1, savedWordCount: 1, readBookCount: 1, isPublic: isPublic, roomTheme: roomTheme); return profile
    }
    func logout(refreshToken: String, baseURL: URL,
                    session: URLSession) async throws {
        return
    }
    func withdraw(token: String) async throws {
        return
    }
    func uploadProfileImage(
            token: String,
            imageData: Data,
            fileName: String,
            mimeType: String
        ) async throws -> String {
        return ""
    }
}
#endif
