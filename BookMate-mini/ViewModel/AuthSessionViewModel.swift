//
//  AuthSessionViewModel.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI
import Combine
@MainActor
final class AuthSessionViewModel: ObservableObject {
    @Published var currentUser: AuthUser?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var isCheckingSession = true
    @Published var errorMessage: String?
    @Published var profile: ProfileResponse?

    
    private let authAPIService = AuthAPIService()
    private let tokenStore: AuthTokenStore = KeychainTokenStore()
    private let kakaoLoginService = KakaoLoginService()
    
    // AuthSessionViewModel이 처음 만들어지는 순간,
    //    비동기 작업을 하나 시작해서,
    //    이전에 로그인했던 세션이 있는지 확인해라.
    init() {
        Task {
            await restoreSession()
        }
    }
    
    //    로그인 성공
    //    → 토큰 저장
    //    → currentUser 저장
    //    → /api/me로 프로필 상세 정보 조회
    //    → profile에 저장
    //    → ProfileView가 이 값을 보여줌
    
    func login(email: String, password: String) async {
        
        isLoading = true
        errorMessage = nil
        
        do { // 로그인 성공 토큰 저장 → 서버에서 accessToken 받음 → KeychainTokenStore에 저장 → 로그인 상태 true
            let response = try await authAPIService.login(email: email, password: password)
            
            // 여기서 토큰 저장
            tokenStore.save(response.accessToken)
            
            currentUser = response.user
            isLoggedIn = true
            
            await loadProfile()
        } catch {
            errorMessage = "로그인에 실패했습니다."
            print("로그인 실패:", error)
        }
        
        isLoading = false
    }
    
    
//    loginWithKakao()
//    → KakaoLoginService에서 카카오 accessToken 받음
//    → AuthAPIService가 백엔드 /api/auth/kakao 호출
//    → 백엔드가 우리 앱 accessToken 발급
//    → Keychain 저장
//    → 로그인 상태 true
    func loginWithKakao() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("카카오 로그인 시작")

                    let kakaoAccessToken = try await kakaoLoginService.login()
                    print("카카오 accessToken 받음")

                    print("백엔드 카카오 로그인 요청 시작")
                    let response = try await authAPIService.loginWithKakao(
                        accessToken: kakaoAccessToken
                    )
                    print("백엔드 AuthResponse 받음:", response.user.nickname)

                    tokenStore.save(response.accessToken)
                    print("BookMate 토큰 Keychain 저장 완료")

                    currentUser = response.user
                    isLoggedIn = true
                    print("isLoggedIn true 변경 완료")
            
            await loadProfile()
        } catch {
            errorMessage = "카카오 로그인에 실패했습니다."
            print("카카오 로그인 실패:", error)
        }
        isLoading = false
    }
    
    
    
    
    // 1. Keychain에서 저장된 accessToken을 꺼낸다.
    //   2. 토큰이 없으면 로그인 안 된 상태로 둔다.
    //   3. 토큰이 있으면 서버에 /api/me 요청을 보낸다.
    //   4. 서버가 사용자 정보를 정상 응답하면 로그인 상태로 복구한다.
    //   5. 서버가 거절하면 토큰을 지우고 로그인 화면으로 보낸다.
    
    // 저장된 토큰을 이용해서 로그인 상태를 복구한다
    func restoreSession() async {
        guard let token = tokenStore.load() else {
            isCheckingSession = false
            isLoggedIn = false
            return
        }
        
        do { // 서버에 “이 토큰 유효해? 이 사용자 정보 줘”라고 물어봄
            let profile = try await authAPIService.fetchProfile(token: token)
            
            self.profile = profile
            currentUser = profile.toAuthUser()
            isLoggedIn = true
        } catch {
            tokenStore.clear()
            currentUser = nil
            isLoggedIn = false
            print("로그인 세션 복구 실패:", error)
        }
        isCheckingSession = false
    }
    
    func logout() {
        tokenStore.clear()
        currentUser = nil
        isLoggedIn = false
        profile = nil
    }
    
    //    회원가입 요청 시작
    //    → isLoading = true
    //    → 버튼 문구를 "가입 중..."으로 바꿈
    //    → 버튼 중복 클릭 막음
    //    → 서버 응답 기다림
    //    → 응답 끝남
    //    → isLoading = false
    
    func signup(email: String, password: String, nickname: String) async {
        isLoading = true // 회원가입 요청 중이라는 상태 표시
        errorMessage = nil
        
        do {
            let response = try await authAPIService.signup(email: email, password: password, nickname: nickname)
            
            tokenStore.save(response.accessToken)
            
            currentUser = response.user
            isLoggedIn = true
            
            await loadProfile()
        } catch {
            errorMessage = "회원가입에 실패했습니다."
            print("회원가입 실패:", error)
        }
        
        isLoading = false
    }

    func loadProfile() async {
        guard let token = tokenStore.load() else { return }
        
        do {
            profile = try await authAPIService.fetchProfile(token: token)
            
            self.profile = profile
            currentUser = profile?.toAuthUser()
        } catch {
            errorMessage = "프로필 정보를 불러오지 못했습니다."
            print("프로필 조회 실패:", error)
        }
    }
    
    func updateProfile(nickname: String, profileImageUrl: String?) async -> Bool {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedProfile = try await authAPIService.updateProfile(token: token, nickname: nickname, profileImageUrl: profileImageUrl)
            
            profile = updatedProfile
            currentUser = updatedProfile.toAuthUser()
            
//            await loadProfile()
            
            isLoading = false
            return true
        } catch {
            errorMessage = "프로필 수정에 실패했습니다."
            isLoading = false
            print("프로필 수정 실패:", error)
            return false
        }
    }
    
    func withdraw() async {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authAPIService.withdraw(token: token)
            
            tokenStore.clear()
            currentUser = nil
            profile = nil
            isLoggedIn = false
        } catch {
            errorMessage = "회원 탈퇴에 실패했습니다."
            print("회원 탈퇴 실패:", error)
        }
         
        isLoading = false
    }
    
    func uploadProfileImage(imageData: Data) async -> String? {
        guard let token = tokenStore.load() else {
            errorMessage = "로그인이 필요합니다."
            return nil
        }
        
        do {
            return try await authAPIService.uploadProfileImage(token: token, imageData: imageData)
        } catch {
            errorMessage = "프로필 이미지 업로드에 실패했습니다."
            print("프뢸 이미지 업로드 실패:", error)
            return nil
        }
    }
    
}
