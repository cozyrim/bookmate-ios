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

private actor PushTokenSyncState {
    private let failedSyncRetryCooldown: TimeInterval
    private var isSyncing = false
    private var lastFailedSyncAt: Date?

    init(failedSyncRetryCooldown: TimeInterval) {
        self.failedSyncRetryCooldown = failedSyncRetryCooldown
    }

    func beginSyncIfPossible() -> Bool {
        guard !isSyncing else {
            return false
        }

        if let lastFailedSyncAt,
           Date().timeIntervalSince(lastFailedSyncAt) < failedSyncRetryCooldown {
            return false
        }

        isSyncing = true
        return true
    }

    func finishSync(succeeded: Bool) {
        isSyncing = false
        lastFailedSyncAt = succeeded ? nil : Date()
    }
}

final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    private let latestFCMTokenKey = "latestFCMToken"
    private let appDeviceIdKey = "appDeviceId"

    private let apiService = NotificationAPIService()
    private let tokenStore: AuthTokenStore = KeychainTokenStore()
    private let syncState = PushTokenSyncState(failedSyncRetryCooldown: 60)

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

    func requestAuthorizationAndRegisterForRemoteNotifications() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])

                guard granted else {
                    return
                }
            } catch {
                DebugLogger.log("알림 권한 요청 실패:", error)
                return
            }
        case .denied:
            return
        @unknown default:
            return
        }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }

        await syncTokenWithServerIfPossible(forceRefreshToken: true)
    }

    func syncTokenWithServerIfPossible(forceRefreshToken: Bool = false) async {
        guard await syncState.beginSyncIfPossible() else { return }

        await registerForRemoteNotificationsIfAuthorized()

        guard tokenStore.load() != nil else {
            await syncState.finishSync(succeeded: true)
            return
        }

        guard let fcmToken = await currentFCMToken(forceRefresh: forceRefreshToken) else {
            await syncState.finishSync(succeeded: true)
            return
        }

        do {
            try await apiService.upsertDeviceToken(
                token: fcmToken,
                deviceId: appDeviceId,
                appVersion: appVersion
            )
            await syncState.finishSync(succeeded: true)
            DebugLogger.log("FCM 토큰 서버 등록 완료")
        } catch {
            await syncState.finishSync(succeeded: false)
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
        latestFCMToken = nil

        Task {
            await syncTokenWithServerIfPossible(forceRefreshToken: true)
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

    private func currentFCMToken(forceRefresh: Bool = false) async -> String? {
        if !forceRefresh, let latestFCMToken {
            return latestFCMToken
        }

        if !forceRefresh, let fcmToken = Messaging.messaging().fcmToken {
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            PushNotificationRouter.shared.route(userInfo: userInfo)
            completionHandler()
        }
    }
}
