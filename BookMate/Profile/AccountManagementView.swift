//
//  AccountManagementView.swift
//  BookMate
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct AccountManagementView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    @State private var isShowingWithdrawAlert = false
    
    private var profile: ProfileResponse? {
            authViewModel.profile
        }

        private var emailText: String {
            profile?.email ?? "이메일 정보 없음"
        }

        private var providerText: String {
            switch profile?.provider.uppercased() {
            case "LOCAL":
                return "이메일 로그인"
            case "KAKAO":
                return "카카오 로그인"
            default:
                return profile?.provider ?? "알 수 없음"
            }
        }

        private var createdAtText: String {
            guard let createdAt = profile?.createdAt else {
                return "가입일 정보 없음"
            }
            return String(createdAt.prefix(10))
        }
    
    
    
    var body: some View {
        ZStack {
                    Color("AppBackground")
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        SettingsScreenHeader(title: "계정 관리")

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                SettingsSectionCard(title: "계정 정보") {
                                    SettingsValueRow(
                                        iconName: "envelope",
                                        title: "이메일",
                                        value: emailText,
                                        showsChevron: false
                                    )

                                    SettingsDivider()

                                    SettingsValueRow(
                                        iconName: "person.badge.key",
                                        title: "로그인 방식",
                                        value: providerText,
                                        showsChevron: false
                                    )

                                    SettingsDivider()

                                    SettingsValueRow(
                                        iconName: "calendar",
                                        title: "가입일",
                                        value: createdAtText,
                                        showsChevron: false
                                    )
                                }
                                Button(role: .destructive) {
                                    isShowingWithdrawAlert = true
                                } label: {
                                    Text("회원 탈퇴")
                                }
                                .alert("정말 탈퇴하시겠어요?", isPresented: $isShowingWithdrawAlert) {
                                    Button("취소", role: .cancel) { }

                                    Button("탈퇴하기", role: .destructive) {
                                        Task {
                                            await authViewModel.withdraw()
                                        }
                                    }
                                } message: {
                                    Text("탈퇴하면 저장한 책과 단어가 모두 삭제되며 복구할 수 없습니다.")
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                        }

                        Spacer()
                        
                    }
                }
        
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .tabBar)
                .task {
                    if authViewModel.profile == nil {
                        await authViewModel.loadProfile()
                    }
                }
    }
}

#Preview {
    AccountManagementView(authViewModel: AuthSessionViewModel())
}
