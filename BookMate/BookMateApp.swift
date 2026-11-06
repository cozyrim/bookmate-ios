//
//  BookMateApp.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import FirebaseCore

@main
struct BookMateApp: App {
    private let dependencies = AppDependencies.bootstrap()
    @UIApplicationDelegateAdaptor(BookMateAppDelegate.self) private var appDelegate
    @AppStorage("appColorMode") private var appColorMode = AppColorMode.system.rawValue

    init() {
        if AppDependencies.usesUIFixtures { return }
        guard let kakaoNativeAppKey = Bundle.main.object(
            forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY"
        ) as? String,
              !kakaoNativeAppKey.isEmpty else {
            fatalError("KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.")
        }

        KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
        FirebaseApp.configure()
        PushNotificationService.shared.configure()
    }
    
    private var preferredScheme: ColorScheme? {
        AppColorMode(rawValue: appColorMode)?.colorScheme
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .preferredColorScheme(preferredScheme)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
