//
//  LoginView.swift
//  BookMate
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var appleAuthorizationCoordinator = AppleAuthorizationCoordinator()
    @FocusState private var focusedField: LoginField?
    
    private static let loginButtonFont = Font.system(size: 18, weight: .bold)
    private static let loginButtonHeight: CGFloat = 56
    
    private enum LoginField {
        case email
        case password
    }
    
    private func submitLogin() {
        Task {
            await authViewModel.login(
                email: email,
                password: password
            )
        }
    }

    private func startAppleLogin() {
        appleAuthorizationCoordinator.start { result in
            switch result {
            case .success(let authorization):
                Task {
                    await authViewModel.loginWithApple(authorization: authorization)
                }
            case .failure(let error):
                Task { @MainActor in
                    authViewModel.handleAppleAuthorizationFailure(error)
                }
            }
        }
    }
    
    
    
    var body: some View {
        NavigationStack {
            ZStack{
                AppBackgroundView()
                
                VStack(spacing: 20) {
                    Image("BookMatePlainIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: Color("Shadow").opacity(0.08), radius: 18, x: 0, y: 8)
                        .padding(.bottom, 4)

                    Text("Bookmate")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextSecondary"))
                    
                    VStack(spacing: 12) {
                        TextField("이메일", text: $email) // focused, submitLabel, onSubmit은 TextField에 붙이는 modifier
                            .focused($focusedField, equals: .email) // focusedField는 현재 커서가 어느 입력칸에 있는지 저장하는 변수
                            .submitLabel(.next) // 키보드 오른쪽 아래 버튼 모양/문구를 정함, 이메일 입력칸에서 다음 칸으로 이동(키보드 버튼의 의미를 바꿔주는 역할)
                                .onSubmit { // 사용자가 키보드에서 next/return 버튼 눌렀을 때 실행되는 코드
                                    focusedField = .password
                                }
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color("Surface").opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        SecureField("비밀번호", text: $password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                                .onSubmit {
                                    submitLogin()
                                }
                            .padding()
                            .background(Color("Surface").opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color("Error"))
                    }
                    Button {
                        submitLogin()
                    } label: {
                        Text(authViewModel.isLoading ? "로그인 중..." : "로그인")
                            .font(Self.loginButtonFont)
                            .frame(maxWidth: .infinity)
                            .frame(height: Self.loginButtonHeight)
                            .background(Color("Primary"))
                            .foregroundStyle(Color("PrimaryButtonText"))
                            .clipShape(Capsule())
                    }
                    .disabled(authViewModel.isLoading)
                    
                    Button {
                        Task {
                            await authViewModel.loginWithKakao()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")

                            Text("카카오로 로그인")
                        }
                        .font(Self.loginButtonFont)
                        .frame(maxWidth: .infinity)
                        .frame(height: Self.loginButtonHeight)
                        .background(Color(red: 1.0, green: 0.90, blue: 0.0))
                        .foregroundStyle(Color("LightButtonText").opacity(0.88))
                        .clipShape(Capsule())
                    }
                    .disabled(authViewModel.isLoading)

                    Button {
                        startAppleLogin()
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")

                            Text("Apple로 로그인")
                        }
                        .font(Self.loginButtonFont)
                        .frame(maxWidth: .infinity)
                        .frame(height: Self.loginButtonHeight)
                        .background(Color.black)
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(authViewModel.isLoading)
                    .accessibilityLabel("Apple로 로그인")
                    
                    NavigationLink {
                        SignupView(authViewModel: authViewModel)
                    } label: {
                        HStack(spacing: 0) {
                            Text("아직 계정이 없나요? ")

                            Text("회원가입")
                                .underline()
                        }
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextSecondary"))
                    }
                    .accessibilityLabel("아직 계정이 없나요? 회원가입")
                    
                }
                .padding(28)
            }
        }
    }
}
#Preview {
    LoginView(authViewModel: AuthSessionViewModel())
}

private final class AppleAuthorizationCoordinator: NSObject {
    private var completion: ((Result<ASAuthorization, Error>) -> Void)?

    func start(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func finish(with result: Result<ASAuthorization, Error>) {
        completion?(result)
        completion = nil
    }
}

extension AppleAuthorizationCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        finish(with: .success(authorization))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finish(with: .failure(error))
    }
}

extension AppleAuthorizationCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)

        if let keyWindow = windows.first(where: \.isKeyWindow) {
            return keyWindow
        }

        if let firstWindow = windows.first {
            return firstWindow
        }

        if let scene = scenes.first {
            return UIWindow(windowScene: scene)
        }

        preconditionFailure("Apple 로그인 표시를 위한 window scene을 찾을 수 없습니다.")
    }
}
