//
//  AuthSessionViewModel.swift
//  BookMate
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI
import Combine
import AuthenticationServices

@MainActor
final class AuthSessionViewModel: ObservableObject {
    // MARK: - Session State

    // 현재 로그인한 사용자와 로그인 여부를 관리한다.
    @Published var currentUser: AuthUser?
    @Published var isLoggedIn = false

    // 인증 요청 중 화면 상태를 제어한다.
    @Published var isLoading = false
    @Published var isCheckingSession = true
    @Published var errorMessage: String?
    @Published var accountDeletionSuccessMessage: String?
    @Published var shouldRequestNotificationPermissionAfterSignup = false

    // 프로필 화면에서 보여줄 사용자 상세 정보를 저장한다.
    @Published var profile: ProfileResponse?

    // MARK: - Services

    private let authAPIService = AuthAPIService()
    private let tokenStore: AuthTokenStore = KeychainTokenStore()
    private let kakaoLoginService = KakaoLoginService()
    private let appleLoginService = AppleLoginService()

    // MARK: - Lifecycle

    // ViewModel이 만들어지면 저장된 토큰으로 로그인 세션을 복구한다.
    init() {
        Task {
            await restoreSession()
        }
    }

    // MARK: - Login

    // 이메일과 비밀번호로 로그인하고 토큰과 사용자 정보를 저장한다.
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authAPIService.login(email: email, password: password)

            saveSessionTokens(from: response)
            currentUser = response.user
            isLoggedIn = true
            BMAnalytics.setUser(response.user)
            BMAnalytics.loginCompleted(method: "email")

            await loadProfile()
            await PushNotificationService.shared.syncTokenWithServerIfPossible()
        } catch {
            BMAnalytics.loginFailed(method: "email", error: error)
            errorMessage = "로그인에 실패했습니다."
            DebugLogger.log("로그인 실패:", error)
        }

        isLoading = false
    }

    // 카카오 accessToken을 백엔드 토큰으로 교환하고 로그인 상태를 저장한다.
    func loginWithKakao() async {
        isLoading = true
        errorMessage = nil

        do {
            let kakaoAccessToken = try await kakaoLoginService.login()
            let response = try await authAPIService.loginWithKakao(
                accessToken: kakaoAccessToken
            )

            saveSessionTokens(from: response)
            currentUser = response.user
            isLoggedIn = true
            BMAnalytics.setUser(response.user)
            BMAnalytics.loginCompleted(method: "kakao")

            await loadProfile()
            await PushNotificationService.shared.syncTokenWithServerIfPossible()
        } catch {
            BMAnalytics.loginFailed(method: "kakao", error: error)
            errorMessage = "카카오 로그인에 실패했습니다."
            DebugLogger.log("카카오 로그인 실패:", error)
        }

        isLoading = false
    }

    // Apple identityToken을 백엔드 토큰으로 교환하고 로그인 상태를 저장한다.
    func loginWithApple(authorization: ASAuthorization) async {
        isLoading = true
        errorMessage = nil

        do {
            let credentials = try appleLoginService.credentials(from: authorization)
            let response = try await authAPIService.loginWithApple(credentials: credentials)

            saveSessionTokens(from: response)
            currentUser = response.user
            isLoggedIn = true
            BMAnalytics.setUser(response.user)
            BMAnalytics.loginCompleted(method: "apple")

            await loadProfile()
            await PushNotificationService.shared.syncTokenWithServerIfPossible()
        } catch {
            BMAnalytics.loginFailed(method: "apple", error: error)
            errorMessage = error.bookMateUserMessage(fallback: "로그인에 실패했습니다.")
            DebugLogger.log("Apple 로그인 실패:", error)
        }

        isLoading = false
    }

    func handleAppleAuthorizationFailure(_ error: Error) {
        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            return
        }

        BMAnalytics.loginFailed(method: "apple", error: error)
        errorMessage = "로그인에 실패했습니다."
        DebugLogger.log("Apple 로그인 실패:", error)
    }

    // 회원가입 후 받은 토큰으로 바로 로그인 상태를 만든다.
    func signup(email: String, password: String, nickname: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authAPIService.signup(
                email: email,
                password: password,
                nickname: nickname
            )

            saveSessionTokens(from: response)
            currentUser = response.user
            shouldRequestNotificationPermissionAfterSignup = true
            isLoggedIn = true
            BMAnalytics.setUser(response.user)
            BMAnalytics.signUpCompleted(method: "email")

            await loadProfile()
            await PushNotificationService.shared.syncTokenWithServerIfPossible()
        } catch {
            BMAnalytics.signUpFailed(method: "email", error: error)
            errorMessage = "회원가입에 실패했습니다."
            DebugLogger.log("회원가입 실패:", error)
        }

        isLoading = false
    }

    // 서버에서 중복되지 않는 랜덤 닉네임을 추천받는다.
    func suggestNickname() async -> String? {
        do {
            return try await authAPIService.fetchNicknameSuggestion()
        } catch {
            errorMessage = "닉네임 추천에 실패했습니다."
            DebugLogger.log("닉네임 추천 실패:", error)
            return nil
        }
    }

    func checkEmailAvailability(email: String) async -> EmailAvailabilityResponse? {
        do {
            return try await authAPIService.checkEmailAvailability(email: email)
        } catch {
            errorMessage = "이메일 중복 확인에 실패했습니다."
            DebugLogger.log("이메일 중복 확인 실패:", error)
            return nil
        }
    }

    func checkNicknameAvailability(nickname: String) async -> NicknameAvailabilityResponse? {
        do {
            return try await authAPIService.checkNicknameAvailability(nickname: nickname)
        } catch {
            errorMessage = "닉네임 중복 확인에 실패했습니다."
            DebugLogger.log("닉네임 중복 확인 실패:", error)
            return nil
        }
    }

    // Keychain에 저장된 토큰으로 앱 재실행 후 로그인 상태를 복구한다.
    func restoreSession() async {
        guard let token = tokenStore.load() else {
            isCheckingSession = false
            isLoggedIn = false
            return
        }

        do {
            let profile = try await authAPIService.fetchProfile(token: token)

            self.profile = profile
            currentUser = profile.toAuthUser()
            isLoggedIn = true
            BMAnalytics.setUser(currentUser)
            await PushNotificationService.shared.syncTokenWithServerIfPossible()
        } catch {
            tokenStore.clear()
            currentUser = nil
            isLoggedIn = false
            BMAnalytics.setUser(nil)
            DebugLogger.log("로그인 세션 복구 실패:", error)
        }

        isCheckingSession = false
    }

    // 저장된 토큰과 사용자 상태를 지우고 로그아웃 상태로 전환한다.
    func logout() {
        let accessToken = tokenStore.load()
        Task {
            await PushNotificationService.shared.disableCurrentTokenOnServer(accessToken: accessToken)
        }

        tokenStore.clear()
        currentUser = nil
        isLoggedIn = false
        profile = nil
        BMAnalytics.setUser(nil)
        BMAnalytics.logoutCompleted()
    }

    // 회원 탈퇴 요청이 성공하면 로컬 로그인 상태도 함께 정리한다.
    func withdraw() async {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let provider = profile?.provider ?? currentUser?.provider
            let shouldUnlinkKakao = provider?.uppercased() == "KAKAO"

            try await authAPIService.withdraw(token: token)

            if shouldUnlinkKakao {
                do {
                    try await kakaoLoginService.unlink()
                } catch {
                    DebugLogger.log("카카오 연결 해제 실패:", error)
                }
            }

            await PushNotificationService.shared.disableCurrentTokenOnServer(accessToken: token)
            tokenStore.clear()
            currentUser = nil
            profile = nil
            isLoggedIn = false
            accountDeletionSuccessMessage = "회원 탈퇴가 완료되었어요."
            BMAnalytics.setUser(nil)
            BMAnalytics.logoutCompleted()
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                isLoading = false
                return
            }

            errorMessage = "잠시 후 다시 시도해 주세요."
            DebugLogger.log("회원 탈퇴 실패:", error)
        }

        isLoading = false
    }

    // MARK: - Profile

    // 서버에서 내 프로필 정보를 다시 불러온다.
    func loadProfile() async {
        guard let token = tokenStore.load() else { return }

        do {
            let profile = try await authAPIService.fetchProfile(token: token)

            self.profile = profile
            currentUser = profile.toAuthUser()
        } catch {
            errorMessage = "프로필 정보를 불러오지 못했습니다."
            DebugLogger.log("프로필 조회 실패:", error)
        }
    }

    // 닉네임, 프로필 이미지, 공개 여부를 수정한다.
    func updateProfile(nickname: String, profileImageUrl: String?, isPublic: Bool) async -> Bool {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return false
        }

        isLoading = true
        errorMessage = nil
        let previousProfile = profile
        let previousUser = currentUser

        do {
            let updatedProfile = try await authAPIService.updateProfile(
                token: token,
                nickname: nickname,
                profileImageUrl: profileImageUrl,
                isPublic: isPublic,
                roomTheme: profile?.roomTheme ?? currentUser?.roomTheme ?? MiniRoomTheme.basic.rawValue
            )

            profile = updatedProfile
            currentUser = updatedProfile.toAuthUser()
            BMAnalytics.setUser(currentUser)
            BMAnalytics.profileUpdated(
                changedFields: changedProfileFields(
                    previousProfile: previousProfile,
                    previousUser: previousUser,
                    nickname: nickname,
                    profileImageUrl: profileImageUrl,
                    isPublic: isPublic
                ),
                isPublic: updatedProfile.isPublic
            )
            isLoading = false
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                isLoading = false
                return false
            }

            errorMessage = "프로필 수정에 실패했습니다."
            isLoading = false
            BMAnalytics.profileUpdateFailed(error: error)
            DebugLogger.log("프로필 수정 실패:", error)
            return false
        }
    }

    func updateMiniRoomTheme(_ theme: MiniRoomTheme) async -> Bool {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return false
        }

        guard let user = currentUser else {
            errorMessage = "사용자 정보를 찾지 못했습니다."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let updatedProfile = try await authAPIService.updateProfile(
                token: token,
                nickname: profile?.nickname ?? user.nickname,
                profileImageUrl: profile?.profileImageUrl ?? user.profileImageUrl,
                isPublic: profile?.isPublic ?? user.isPublic ?? true,
                roomTheme: theme.rawValue
            )

            profile = updatedProfile
            currentUser = updatedProfile.toAuthUser()
            BMAnalytics.setUser(currentUser)
            BMAnalytics.miniRoomThemeUpdated(theme: theme.rawValue)
            isLoading = false
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                isLoading = false
                return false
            }

            errorMessage = "서재 배경 저장에 실패했습니다."
            isLoading = false
            DebugLogger.log("서재 배경 저장 실패:", error)
            return false
        }
    }

    // 선택한 프로필 이미지를 서버에 업로드하고 이미지 URL을 반환한다.
    func uploadProfileImage(imageData: Data) async -> String? {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return nil
        }

        do {
            let uploadedURL = try await authAPIService.uploadProfileImage(token: token, imageData: imageData)
            BMAnalytics.profileImageChanged(source: "photo_library")
            return uploadedURL
        } catch {
            if handleUnauthorizedIfNeeded(error) { return nil }

            errorMessage = "프로필 이미지 업로드에 실패했습니다."
            BMAnalytics.profileImageUploadFailed(error: error)
            DebugLogger.log("프로필 이미지 업로드 실패:", error)
            return nil
        }
    }

    private func changedProfileFields(
        previousProfile: ProfileResponse?,
        previousUser: AuthUser?,
        nickname: String,
        profileImageUrl: String?,
        isPublic: Bool
    ) -> [String] {
        var fields: [String] = []
        let previousNickname = previousProfile?.nickname ?? previousUser?.nickname
        let previousProfileImageUrl = previousProfile?.profileImageUrl ?? previousUser?.profileImageUrl
        let previousIsPublic = previousProfile?.isPublic ?? previousUser?.isPublic

        if previousNickname != nickname {
            fields.append("nickname")
        }

        if previousProfileImageUrl != profileImageUrl {
            fields.append(profileImageUrl == nil ? "profile_image_reset" : "profile_image")
        }

        if previousIsPublic != isPublic {
            fields.append("visibility")
        }

        return fields.isEmpty ? ["none"] : fields
    }

    private func saveSessionTokens(from response: AuthResponse) {
        guard let refreshToken = response.refreshToken else {
            tokenStore.save(response.accessToken)
            return
        }

        tokenStore.save(accessToken: response.accessToken, refreshToken: refreshToken)
    }

    // MARK: - Helpers

    // 401 응답이면 토큰이 만료된 상태로 보고 로그아웃 처리한다.
    private func handleUnauthorizedIfNeeded(_ error: Error) -> Bool {
        if case APIError.unauthorized = error {
            logout()
            return true
        }

        return false
    }
}
