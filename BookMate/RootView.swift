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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let dependencies: AppDependencies
    @StateObject private var authViewModel: AuthSessionViewModel

    init(dependencies: AppDependencies? = nil) {
        let dependencies = dependencies ?? AppDependencies()
        self.dependencies = dependencies
        _authViewModel = StateObject(wrappedValue: AuthSessionViewModel(dependencies: dependencies))
    }
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var toast: AppToast?
//    RootView가 AuthSessionViewModel을 처음 만들고 소유한다.
//    앱의 로그인 상태는 RootView가 들고 있는다.

    
    var body: some View {
        ZStack {
            if !authViewModel.isCheckingSession {
                destination
                    .transition(.identity)
            }
            if authViewModel.isCheckingSession {
                SessionLoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: reduceMotion ? 0.15 : 0.24), value: authViewModel.isCheckingSession)
        .phoneWidthOnWideScreens()
        .dismissKeyboardOnTap()
        .appToast($toast)
        .onChange(of: authViewModel.accountDeletionSuccessMessage) { _, message in
            guard let message else { return }
            toast = AppToast(message: message, style: .success)
            authViewModel.accountDeletionSuccessMessage = nil
        }
    }
    @ViewBuilder
    private var destination: some View {
        if let message = authViewModel.sessionRestoreError {
            ContentStateView(type: .error, iconName: "wifi.exclamationmark", title: "연결을 확인해 주세요", message: message, buttonTitle: "다시 시도", buttonIconName: "arrow.clockwise") {
                Task { await authViewModel.restoreSession() }
            }
        } else if !hasSeenOnboarding {
            OnboardingView { hasSeenOnboarding = true }
        } else if authViewModel.isLoggedIn {
            MainTabView(authViewModel: authViewModel, dependencies: dependencies)
                .environmentObject(authViewModel)
        } else {
            LoginView(authViewModel: authViewModel)
        }
    }
}
#Preview {
    RootView()
}

private extension View {
    func phoneWidthOnWideScreens(maxWidth: CGFloat = 520) -> some View {
        modifier(PhoneWidthOnWideScreensModifier(maxWidth: maxWidth))
    }
}

private struct PhoneWidthOnWideScreensModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                content
                    .frame(maxWidth: maxWidth, maxHeight: .infinity)
                    .background(Color("AppBackground"))
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            content
        }
    }
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
