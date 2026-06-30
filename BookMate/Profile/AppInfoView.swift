//
//  AppInfoView.swift
//  BookMate
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct AppInfoView: View {
    @Environment(\.openURL) private var openURL

    private let privacyPolicyURL = URL(string: "https://bookmate.kr/privacy/")!
    private let termsURL = URL(string: "https://bookmate.kr/terms/")!

    var body: some View {
        ZStack {
            AppBackgroundView()
            
            VStack(spacing: 24) {
                SettingsScreenHeader(title: "앱 정보")
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
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
                        .padding(.top, 4)
                        
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

                        SettingsSectionCard(title: "약관 및 정책") {
                            SettingsNavigationRow(
                                iconName: "doc.text",
                                title: "개인정보 처리방침",
                                value: "보기"
                            ) {
                                openURL(privacyPolicyURL)
                            }

                            SettingsDivider()

                            SettingsNavigationRow(
                                iconName: "doc.plaintext",
                                title: "이용약관",
                                value: "보기"
                            ) {
                                openURL(termsURL)
                            }
                        }

                        Text("© 2026 BookMate")
                            .font(.caption)
                            .foregroundStyle(Color("TextMuted"))
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
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
