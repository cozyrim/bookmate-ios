//
//  BookMateAppDelegate.swift
//  BookMate
//
//  Created by Codex on 6/28/26.
//

import UIKit

final class BookMateAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationService.shared.handleAPNsDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        DebugLogger.log("APNs 토큰 등록 실패:", error)
    }
}
