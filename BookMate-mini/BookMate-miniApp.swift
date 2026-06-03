//
//  BookMateApp.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct BookMateApp: App {
    @AppStorage("appColorMode") private var appColorMode = AppColorMode.system.rawValue

    init() {
        guard let kakaoNativeAppKey = Bundle.main.object(
            forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY"
        ) as? String,
              !kakaoNativeAppKey.isEmpty else {
            fatalError("KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.")
        }

        KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
    }
    
    private var preferredScheme: ColorScheme? {
        AppColorMode(rawValue: appColorMode)?.colorScheme
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(preferredScheme)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
