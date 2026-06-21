import SwiftUI

//struct RootView: View {
//    var body: some View {
//        MainTabView()
//    }
//}
//
//#Preview {
//    RootView()
//}

//RootView 생성
//→ AuthSessionViewModel 생성
//→ init 실행
//→ restoreSession 실행
//→ 저장된 토큰 확인
//→ 로그인 상태 결정


struct RootView: View {
    @StateObject private var authViewModel = AuthSessionViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
//    RootView가 AuthSessionViewModel을 처음 만들고 소유한다.
//    앱의 로그인 상태는 RootView가 들고 있는다.

    
    var body: some View {
        Group {
            if authViewModel.isCheckingSession {
                ZStack {
                    Color("AppBackground")
                        .ignoresSafeArea()

                    ProgressView()
                }
            } else if authViewModel.isLoggedIn {
                MainTabView(authViewModel: authViewModel)
                    .environmentObject(authViewModel)
            } else if !hasSeenOnboarding {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
        .dismissKeyboardOnTap()
    }
}
#Preview {
    RootView()
}

//앱 시작
//→ 온보딩 본 적 있음?
//→ 토큰 있음?
//→ 로그인 상태 확인
//→ MainTabView 또는 LoginView
//    isCheckingSession == true
//    → 로그인 확인 중 화면
//
//    isCheckingSession == false && isLoggedIn == true
//    → MainTabView
//
//    isCheckingSession == false && isLoggedIn == false
//    → LoginView
