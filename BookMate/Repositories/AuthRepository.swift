import Foundation

protocol AuthRepository {
    func login(email: String, password: String) async throws -> AuthResponse
    func loginWithKakao(accessToken: String) async throws -> AuthResponse
    func loginWithApple(credentials: AppleLoginCredentials) async throws -> AuthResponse
    func signup(email: String, password: String, nickname: String) async throws -> AuthResponse
    func fetchNicknameSuggestion() async throws -> String
    func checkEmailAvailability(email: String) async throws -> EmailAvailabilityResponse
    func checkNicknameAvailability(nickname: String) async throws -> NicknameAvailabilityResponse
    func fetchProfile(token: String) async throws -> ProfileResponse
    func updateProfile(
            token: String,
            nickname: String,
            profileImageUrl: String?,
            isPublic: Bool,
            roomTheme: String
        ) async throws -> ProfileResponse
    func logout(refreshToken: String, baseURL: URL,
                    session: URLSession) async throws
    func withdraw(token: String) async throws
    func uploadProfileImage(
            token: String,
            imageData: Data,
            fileName: String,
            mimeType: String
        ) async throws -> String
}

extension AuthRepository {
    func logout(refreshToken: String) async throws {
        try await logout(refreshToken: refreshToken, baseURL: APIEnvironment.baseURL, session: .shared)
    }
    func uploadProfileImage(token: String, imageData: Data) async throws -> String {
        try await uploadProfileImage(token: token, imageData: imageData, fileName: "profile.jpg", mimeType: "image/jpeg")
    }
}
