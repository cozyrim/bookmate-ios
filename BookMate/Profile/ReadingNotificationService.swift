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
    private let continueReadingReminderIdentifier = "continue-reading-reminder"
    private let legacyRecordReminderIdentifier = "reading-record-reminder"
    private let testReminderIdentifier = "test-reading-reminder"
    private let continueReadingEnabledKey = "continueReadingReminderEnabled"
    private let continueReadingDaysKey = "continueReadingReminderDays"
    
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
        content.body = "모르는 단어는 바로 검색하고, 필요한 단어만 저장해두세요."
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

    func scheduleContinueReadingReminder(afterDays days: Int, book: Book?, shelfBook: ShelfBook?) async {
        cancelContinueReadingReminder()

        let safeDays = max(1, days)
        let content = UNMutableNotificationContent()
        let message = continueReadingMessage(book: book, shelfBook: shelfBook)
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.userInfo = continueReadingUserInfo(book: book)

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(safeDays) * 24 * 60 * 60,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: continueReadingReminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            DebugLogger.log("이어보기 알림 예약 완료:", safeDays)
        } catch {
            DebugLogger.log("이어보기 알림 예약 실패:", error)
        }
    }

    func scheduleContinueReadingReminderIfEnabled(book: Book?, shelfBook: ShelfBook?) async {
        guard isContinueReadingReminderEnabled else { return }

        await scheduleContinueReadingReminder(
            afterDays: continueReadingReminderDays,
            book: book,
            shelfBook: shelfBook
        )
    }

    func cancelContinueReadingReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    continueReadingReminderIdentifier,
                    legacyRecordReminderIdentifier
                ]
            )
    }

    func cancelAllReadingReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                dailyReminderIdentifier,
                continueReadingReminderIdentifier,
                legacyRecordReminderIdentifier,
                testReminderIdentifier
            ]
        )
    }

    private var isContinueReadingReminderEnabled: Bool {
        UserDefaults.standard.object(forKey: continueReadingEnabledKey) as? Bool ?? true
    }

    private var continueReadingReminderDays: Int {
        let savedDays = UserDefaults.standard.integer(forKey: continueReadingDaysKey)
        return savedDays == 0 ? 3 : savedDays
    }

    private func continueReadingMessage(book: Book?, shelfBook: ShelfBook?) -> (title: String, body: String) {
        guard let book else {
            return (
                title: "읽던 책을 이어볼까요?",
                body: "잠깐 멈춘 독서 흐름을 다시 이어가요."
            )
        }

        let title = "『\(book.title)』 이어 읽을까요?"

        if let currentPage = book.currentPage, currentPage > 0 {
            return (
                title: title,
                body: "p.\(currentPage)에서 멈췄어요. 다시 책장을 열어볼까요?"
            )
        }

        let progress = shelfBook?.progress ?? book.progress
        let progressPercent = Int((min(max(progress, 0), 1) * 100).rounded())

        if progressPercent > 0 && progressPercent < 100 {
            return (
                title: title,
                body: "\(progressPercent)%까지 읽었어요. 오늘은 한 장만 더 넘겨봐요."
            )
        }

        return (
            title: title,
            body: "오늘은 한 장만 더 넘겨봐요."
        )
    }

    private func continueReadingUserInfo(book: Book?) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [
            "type": "continue_reading"
        ]

        if let book {
            userInfo["book_id"] = book.id.uuidString
            userInfo["book_title"] = book.title
        }

        return userInfo
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
