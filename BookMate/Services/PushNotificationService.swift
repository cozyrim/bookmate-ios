//
//  PushNotificationService.swift
//  BookMate
//
//  Created by Codex on 6/28/26.
//

import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    private let latestFCMTokenKey = "latestFCMToken"
    private let appDeviceIdKey = "appDeviceId"

    private let apiService = NotificationAPIService()
    private let tokenStore: AuthTokenStore = KeychainTokenStore()

    private override init() {
        super.init()
    }

    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    func registerForRemoteNotificationsIfAuthorized() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let allowedStatuses: [UNAuthorizationStatus] = [.authorized, .provisional, .ephemeral]

        guard allowedStatuses.contains(settings.authorizationStatus) else {
            return
        }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func syncTokenWithServerIfPossible() async {
        await registerForRemoteNotificationsIfAuthorized()

        guard tokenStore.load() != nil else {
            return
        }

        guard let fcmToken = await currentFCMToken() else {
            return
        }

        do {
            try await apiService.upsertDeviceToken(
                token: fcmToken,
                deviceId: appDeviceId,
                appVersion: appVersion
            )
            DebugLogger.log("FCM 토큰 서버 등록 완료")
        } catch {
            DebugLogger.log("FCM 토큰 서버 등록 실패:", error)
        }
    }

    func disableCurrentTokenOnServer(accessToken: String?) async {
        guard let fcmToken = latestFCMToken else {
            return
        }

        do {
            try await apiService.disableDeviceToken(token: fcmToken, accessToken: accessToken)
            DebugLogger.log("FCM 토큰 서버 비활성화 완료")
        } catch {
            DebugLogger.log("FCM 토큰 서버 비활성화 실패:", error)
        }
    }

    func handleAPNsDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        Task {
            await syncTokenWithServerIfPossible()
        }
    }

    private var latestFCMToken: String? {
        get {
            UserDefaults.standard.string(forKey: latestFCMTokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: latestFCMTokenKey)
        }
    }

    private var appDeviceId: String {
        if let savedDeviceId = UserDefaults.standard.string(forKey: appDeviceIdKey) {
            return savedDeviceId
        }

        let newDeviceId = UUID().uuidString
        UserDefaults.standard.set(newDeviceId, forKey: appDeviceIdKey)
        return newDeviceId
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "unknown"
        return "\(version)(\(build))"
    }

    private func currentFCMToken() async -> String? {
        if let latestFCMToken {
            return latestFCMToken
        }

        if let fcmToken = Messaging.messaging().fcmToken {
            latestFCMToken = fcmToken
            return fcmToken
        }

        return await withCheckedContinuation { continuation in
            Messaging.messaging().token { [weak self] token, error in
                if let error {
                    DebugLogger.log("FCM 토큰 조회 실패:", error)
                    continuation.resume(returning: nil)
                    return
                }

                if let token {
                    self?.latestFCMToken = token
                }

                continuation.resume(returning: token)
            }
        }
    }
}

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else {
            return
        }

        latestFCMToken = fcmToken

        Task {
            await syncTokenWithServerIfPossible()
        }
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}
