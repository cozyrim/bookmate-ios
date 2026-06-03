//
//  LoginView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        NavigationStack {
            ZStack{
                Color("AppBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("북메이트")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextSecondary"))
                    
                    VStack(spacing: 12) {
                        TextField("이메일", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color("Surface").opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        SecureField("비밀번호", text: $password)
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
                        Task {
                            await authViewModel.login(
                                email: email,
                                password: password
                            )
                        }
                    } label: {
                        Text(authViewModel.isLoading ? "로그인 중..." : "로그인")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color("Primary"))
                            .foregroundStyle(.white)
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
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 1.0, green: 0.90, blue: 0.0))
                        .foregroundStyle(Color("TextPrimary").opacity(0.85))
                        .clipShape(Capsule())
                    }
                    .disabled(authViewModel.isLoading)
                    
                    NavigationLink {
                        SignupView(authViewModel: authViewModel)
                    } label: {
                        Text("아직 계정이 없나요? 회원가입")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    
                }
                .padding(28)
            }
        }
    }
}
#Preview {
    LoginView(authViewModel: AuthSessionViewModel())
}
