//
//  SignupView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI

struct SignupView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var step = 1
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var nickname = ""
    
    private var canGoNext: Bool {
        email.contains("@") &&
        password.count >= 8 &&
        password == passwordConfirm
    }
    
    private var canSubmit: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 26) {
                header
                
                if step == 1 {
                    accountStep
                } else {
                    nicknameStep
                }
                
                Spacer()
                
                
                Button {
                    if step == 1 {
                        step = 2
                    } else {
                        Task {
                            await authViewModel.signup(email: email, password: password, nickname: nickname)
                        }
                    }
                } label: {
                    Text(step == 1 ? "다음" : "완료")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background((step == 1 ? canGoNext : canSubmit) ? Color("Primary") : Color.gray.opacity(0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color("Primary").opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .disabled(step == 1 ? !canGoNext : !canSubmit)
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }
    
    private var header: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left") {
                if step == 1 {
                    dismiss()
                } else {
                    step = 1
                }
            }
            
            Spacer()
            
            Text("회원가입")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
    }
    
    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepIndicator(current: 1)
            
            Text("계정 정보를\n입력해주세요")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))
            
            Text("북메이트에서 사용할 이메일과 비밀번호를 설정합니다.")
                .foregroundStyle(Color("TextSecondary"))
            
            signupField(title: "이메일 주소", placeholder: "example@bookmate.com", text: $email, icon: "envelope")
            
            secureSignupField(title: "비밀번호", placeholder: "8자 이상 입력해주세요", text: $password)
            
            secureSignupField(title: "비밀번호 확인", placeholder: "비밀번호를 다시 입력해주세요", text: $passwordConfirm)
            
            Text("영문, 숫자를 포함하여 8자 이상으로 설정해주세요.")
                .font(.caption)
                .foregroundStyle(Color("TextSecondary").opacity(0.75))
        }
    }
    
    private var nicknameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepIndicator(current: 2)
            
            VStack(spacing: 18) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 54))
                    .foregroundStyle(Color("PrimaryDeep"))
                    .frame(width: 132, height: 132)
                    .background(Color("Surface").opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .shadow(color: Color("Shadow").opacity(0.05), radius: 12, x: 0, y: 6)
            }
            .frame(maxWidth: .infinity)
            
            Text("사용하실 닉네임을\n설정해주세요")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("북메이트에서 불릴 이름을 정해주세요.")
                .foregroundStyle(Color("TextSecondary"))
            
            signupField(title: "닉네임", placeholder: "북메이트친구", text: $nickname, icon: "sparkles")
            
            HStack(spacing: 12) {
                infoCard(icon: "textformat", title: "한글/영문 가능")
                infoCard(icon: "ruler", title: "최대 10자 추천")
            }
        }
    }
    
    private func stepIndicator(current: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Capsule()
                    .fill(current == 1 ? Color("Primary") : Color.gray.opacity(0.2))
                    .frame(width: 48, height: 6)
                
                Capsule()
                    .fill(current == 2 ? Color("Primary") : Color.gray.opacity(0.2))
                    .frame(width: 48, height: 6)
            }
            
            Spacer()
            
            Text("\(current) / 2")
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryDeep"))
        }
    }
    
    private func signupField(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))
            
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(Color("TextSecondary").opacity(0.75))
                
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color("Surface").opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private func secureSignupField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))
            
            HStack(spacing: 14) {
                Image(systemName: "lock")
                    .foregroundStyle(Color("TextSecondary").opacity(0.75))
                
                SecureField(placeholder, text: text)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color("Surface").opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private func infoCard(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color("PrimaryDeep"))
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(Color("Surface").opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    SignupView(authViewModel: AuthSessionViewModel())
}
