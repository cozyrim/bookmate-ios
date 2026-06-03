//
//  ProfileEditView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
        @Environment(\.dismiss) private var dismiss

        @State private var nickname = ""

        private var currentNickname: String {
            authViewModel.profile?.nickname
            ?? authViewModel.currentUser?.nickname
            ?? ""
        }

    var body: some View {
        ZStack {
                    Color.skyblue
                        .ignoresSafeArea()
            
            VStack(spacing: 24) {
                            SettingsScreenHeader(title: "프로필 수정")

                            VStack(spacing: 18) {
                                ProfileImageView(imageName: "profileImage", showsEditIcon: true) {
                                    print("프로필 이미지 수정은 다음 단계에서 연결")
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                                        Text("닉네임")
                                                            .font(.callout)
                                                            .fontWeight(.semibold)
                                                            .foregroundStyle(Color("Brown"))

                                                        TextField("닉네임을 입력하세요", text: $nickname)
                                                            .padding(.horizontal, 18)
                                                            .frame(height: 58)
                                                            .background(Color.white.opacity(0.88))
                                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                                    }
                                                }
                            .padding(.horizontal, 28)

                                            Spacer()

                                            SettingsPrimaryButton(title: authViewModel.isLoading ? "저장 중..." : "저장하기") {
                                                saveProfile()
                                            }
                                            .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                            .padding(.horizontal, 28)
                                            .padding(.bottom, 24)
                                        }
                                    }
        .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .tabBar)
                .onAppear {
                    nickname = currentNickname
                }
            }
    
    private func saveProfile() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { return }
            
        Task {
            let success = await authViewModel.updateProfile(nickname: trimmedNickname, profileImageUrl: authViewModel.profile?.profileImageUrl)
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    ProfileEditView(authViewModel: AuthSessionViewModel())
}
