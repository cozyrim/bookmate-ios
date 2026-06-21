//
//  AppInfoView.swift
//  BookMate
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack(spacing: 24) {
                SettingsScreenHeader(title: "앱 정보")
                
                VStack(spacing: 14) {
                    Image("BookMatePlainIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color("Shadow").opacity(0.10), radius: 18, y: 8)
                    
                    Text("북메이트")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))

                    Text("책을 읽는 순간마다 함께하는\n나만의 독서 메이트")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color("TextSecondary"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 260)
                }
                .padding(.top, 20)
                
                SettingsSectionCard(title: "기본 정보") {
                    SettingsValueRow(
                        iconName: "info.circle",
                        title: "앱 버전",
                        value: appVersion,
                        showsChevron: false
                    )
                    
                    SettingsDivider()

                    SettingsValueRow(
                        iconName: "person",
                        title: "만든 사람",
                        value: "한채림",
                        showsChevron: false
                    )
                }
                .padding(.horizontal, 28)

                SettingsSectionCard(title: "안내") {
                    SettingsNavigationRow(
                        iconName: "envelope",
                        title: "문의하기",
                        value: "이메일"
                    ) { }
                    
                    SettingsDivider()

                    SettingsNavigationRow(
                        iconName: "doc.text",
                        title: "개인정보 처리방침",
                        value: "보기"
                    ) { }

                    SettingsDivider()

                    SettingsNavigationRow(
                        iconName: "shippingbox",
                        title: "오픈소스 라이브러리",
                        value: "보기"
                    ) { }
                }
                .padding(.horizontal, 28)

                Spacer()

                Text("© 2026 BookMate")
                    .font(.caption)
                    .foregroundStyle(Color("TextMuted"))
                    .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}


#Preview {
    AppInfoView()
}
