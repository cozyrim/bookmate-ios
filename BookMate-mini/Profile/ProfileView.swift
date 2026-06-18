//
//  ProfileView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    @State private var path = NavigationPath()
    @State private var isShowingProfilePreview = false
    
    
    private var userName: String {
        authViewModel.profile?.nickname
        ?? authViewModel.currentUser?.nickname
        ?? "사용자"
    }
    
    private var savedWordCount: Int {
            authViewModel.profile?.savedWordCount ?? 0
        }
    
    private var readBookCount: Int {
            authViewModel.profile?.readBookCount ?? 0
        }

    private var togetherDays: Int {
            authViewModel.profile?.togetherDays ?? 0
        }
    
    private let accountRows = [
        ProfileMenuItem(imageName: "person.crop.circle", title: "프로필 수정", route: .editProfile),
            ProfileMenuItem(imageName: "person.badge.plus", title: "계정 관리", route: .accountManagement),
            ProfileMenuItem(imageName: "bell", title: "알림 설정", route: .notificationSettings)
        ]

        private let settingRows = [
            ProfileMenuItem(imageName: "book", title: "화면 테마", route: .themeSettings),
            ProfileMenuItem(imageName: "moon", title: "다크 모드", route: .darkModeSettings),
            ProfileMenuItem(imageName: "icloud", title: "iCloud 백업")
        ]

        private let supportRows = [
            ProfileMenuItem(imageName: "headphones", title: "고객 센터"),
            ProfileMenuItem(imageName: "info.circle", title: "앱 정보", route: .appInfo),
            ProfileMenuItem(imageName: "rectangle.portrait.and.arrow.right", title: "로그아웃", isDestructive: true, showChevron: false)
        ]
    
    private func handleMenuTap(_ item: ProfileMenuItem) {
        if item.isDestructive {
            authViewModel.logout()
            return
        }

        guard let route = item.route else { return }

        path.append(route)
        // NavigationLink(value:) 대신 코드로 이동하고 싶으면 path가 필요하지만,
        // 여기서는 간단히 NavigationLink 방식이 더 좋아.
    }
    
    
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack{
                Color("AppBackground")
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false){
                    VStack(spacing: 16){
                        
                        profileHeader
                        
                        profileStatsView
                        
                        VStack(spacing: 12){
                            ProfileMenuCardView(rows: accountRows) { item in
                                    handleMenuTap(item)
                            }
                            ProfileMenuCardView(rows: settingRows) { item in
                                handleMenuTap(item)
                            }
                            ProfileMenuCardView(rows: supportRows) { item in
                                handleMenuTap(item)
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .editProfile:
                    ProfileEditView(authViewModel: authViewModel)
                    
                case .accountManagement:
                    AccountManagementView(authViewModel: authViewModel)
                    
                case .notificationSettings:
                    NotificationSettingsView()
                    
                case .themeSettings:
                    ThemeSettingsView()
                    
                case .appInfo:
                    AppInfoView()
                    
                case .darkModeSettings:
                    DarkModeSettingsView()
                }
            }
        }
        .sheet(isPresented: $isShowingProfilePreview) {
            ProfileImagePreviewView(
                imageURLString: authViewModel.profile?.profileImageUrl,
                fallbackImageName: "profileImage"
            )
        }
        .onAppear {
            Task {
                await authViewModel.loadProfile()
            }
        }
    }
        
        private var profileHeader: some View {
            VStack(spacing: 14) {
                ProfileImageView( // 실제 프로필 이미지 보여주기
                    imageName: "profileImage",
                        imageURLString: authViewModel.profile?.profileImageUrl,
                        showsEditIcon: false,
                        onTap: {
                            isShowingProfilePreview = true
                        }
                    )
                Text(userName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))
                
                // 멤버쉽
            }
        }
    
    private var profileStatsView: some View {
        VStack(spacing: 16) {
//            Divider()
            Rectangle()
                .fill(Color("TextSecondary").opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 0) {
                ProfileStatItemView(
                    value: "\(savedWordCount)",
                    label: "저장 단어"
                )

//                Divider()
                Rectangle() // 세로 선
                    .fill(Color("TextSecondary").opacity(0.12))
                    .frame(width: 1, height: 28)
                
                
                    .frame(height: 28)

                ProfileStatItemView(
                    value: "\(readBookCount)",
                    label: "읽은 책"
                )

//                Divider()
                Rectangle() // 새로선
                    .fill(Color("TextSecondary").opacity(0.12))
                    .frame(width: 1, height: 28)
                
                
                    .frame(height: 28)

                ProfileStatItemView(
                    value: "\(togetherDays)일",
                    label: "함께한 날들"
                )
            }

            Rectangle()
                .fill(Color("TextSecondary").opacity(0.08))
                .frame(height: 1)
        }
        .padding(.horizontal, 36)
    }
}
#Preview {
    ProfileView(authViewModel: AuthSessionViewModel())
}
