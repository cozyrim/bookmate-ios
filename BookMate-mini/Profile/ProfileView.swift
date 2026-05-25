//
//  ProfileView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileView: View {
    private let userName = "한독서님"
    
    private let savedWordCount = 128
    private let readBookCount = 12
    private let togetherDays = 45
    
    private let accountRows = [
            ProfileMenuItem(imageName: "person.crop.circle", title: "내 계정"),
            ProfileMenuItem(imageName: "person.badge.plus", title: "프로필 수정"),
            ProfileMenuItem(imageName: "bell", title: "알림 설정")
        ]

        private let settingRows = [
            ProfileMenuItem(imageName: "book", title: "사전 설정"),
            ProfileMenuItem(imageName: "moon", title: "다크 모드"),
            ProfileMenuItem(imageName: "icloud", title: "iCloud 백업")
        ]

        private let supportRows = [
            ProfileMenuItem(imageName: "headphones", title: "고객 센터"),
            ProfileMenuItem(imageName: "info.circle", title: "앱 정보"),
            ProfileMenuItem(imageName: "rectangle.portrait.and.arrow.right", title: "로그아웃", isDestructive: true, showChevron: false)
        ]
    
    
    var body: some View {
        ZStack{
            Color.skyblue
                .ignoresSafeArea()

            ScrollView(showsIndicators: false){
                VStack(spacing: 16){
                
                    profileHeader
    
                    profileStatsView
                    
                    VStack(spacing: 12){
                    ProfileMenuCardView(rows: accountRows)
                    ProfileMenuCardView(rows: settingRows)
                    ProfileMenuCardView(rows: supportRows)
                }
                    .padding(.horizontal, 28)
            }
                .padding(.top, 18)
                .padding(.bottom, 24)
        }
    }
}
    
    private var profileHeader: some View {
        VStack(spacing: 14) {
            ProfileImageView(imageName: "profileImage") {
                print("이미지 선택")
            }
            
            Text(userName)
                .font(.title)
                .fontWeight(.bold)
            
            // 멤버쉽
        }
    }
    
    private var profileStatsView: some View {
        VStack(spacing: 16) {
//            Divider()
            Rectangle()
                .fill(Color("Brown").opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 0) {
                ProfileStatItemView(
                    value: "\(savedWordCount)",
                    label: "단어장"
                )

//                Divider()
                Rectangle() // 세로 선
                    .fill(Color("Brown").opacity(0.12))
                    .frame(width: 1, height: 28)
                
                
                    .frame(height: 28)

                ProfileStatItemView(
                    value: "\(readBookCount)",
                    label: "읽은 책"
                )

//                Divider()
                Rectangle() // 새로선
                    .fill(Color("Brown").opacity(0.12))
                    .frame(width: 1, height: 28)
                
                
                    .frame(height: 28)

                ProfileStatItemView(
                    value: "\(togetherDays)일",
                    label: "함께한 날들"
                )
            }

//            Divider()
            Rectangle()
                .fill(Color("Brown").opacity(0.08))
                .frame(height: 1)
        }
        .padding(.horizontal, 36)
    }
    
}
#Preview {
    ProfileView()
}
