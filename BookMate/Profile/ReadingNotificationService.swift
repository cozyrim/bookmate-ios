//
//  ReadingNotificationService.swift
//  BookMate
//
//  Created by 한채림 on 6/3/26.
//

import UserNotifications

final class ReadingNotificationService {
    static let shared = ReadingNotificationService()

    private let dailyReminderIdentifier = "daily-reading-reminder"
    private let recordReminderIdentifier = "reading-record-reminder"
    private let testReminderIdentifier = "test-reading-reminder"
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            break
        @unknown default:
            break
        }

        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            DebugLogger.log("알림 권한 요청 실패:", error)
            return false
        }
    }

    func scheduleDailyReadingReminder(hour: Int, minute: Int) async {
        cancelDailyReadingReminder()

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "책 읽을 시간이에요"
        content.body = "오늘도 잠깐 책장을 열어볼까요?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            DebugLogger.log("독서 알림 예약 완료:", hour, minute)
        } catch {
            DebugLogger.log("독서 알림 예약 실패:", error)
        }
    }

    func cancelDailyReadingReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }

    func scheduleReadingRecordReminder(afterDays days: Int) async {
        cancelReadingRecordReminder()

        let safeDays = max(1, days)
        let content = UNMutableNotificationContent()
        content.title = "독서 기록을 남겨볼까요?"
        content.body = "\(safeDays)일 동안 기록이 없으면 다시 알려드릴게요."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(safeDays * 24 * 60 * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: recordReminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            DebugLogger.log("기록 리마인드 예약 완료:", safeDays)
        } catch {
            DebugLogger.log("기록 리마인드 예약 실패:", error)
        }
    }

    func cancelReadingRecordReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [recordReminderIdentifier])
    }

    func cancelAllReadingReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                dailyReminderIdentifier,
                recordReminderIdentifier,
                testReminderIdentifier
            ]
        )
    }

#if DEBUG
    func scheduleTestReadingReminder(after seconds: TimeInterval = 18) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [testReminderIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = "책 읽을 시간이에요"
        content.body = "테스트 알림이 도착했어요."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: testReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            DebugLogger.log("테스트 알림 예약 완료:", seconds, "초 뒤")
        } catch {
            DebugLogger.log("테스트 알림 예약 실패:", error)
        }
    }
#endif
}
