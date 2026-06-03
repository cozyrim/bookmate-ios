//
//  ReadingNotificationService.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/3/26.
//

import SwiftUI
import UserNotifications

final class ReadingNotificationService {
    static let shared = ReadingNotificationService()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("알림 권한 요청 실패:", error)
            return false
        }
    }
    
    //    func scheduleDailyReadingReminder(hour: Int, minute: Int) async {
    //        UNUserNotificationCenter.current()
    //            .removePendingNotificationRequests(withIdentifiers: ["daily-reading-reminder"])
    //        
    //        var date = DateComponents()
    //                date.hour = hour
    //                date.minute = minute
    //
    //                let content = UNMutableNotificationContent()
    //                content.title = "책 읽을 시간이에요"
    //                content.body = "오늘도 잠깐 책장을 열어볼까요?"
    //                content.sound = .default
    //
    //                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
    //                let request = UNNotificationRequest(
    //                    identifier: "daily-reading-reminder",
    //                    content: content,
    //                    trigger: trigger
    //                )
    //
    //                try? await UNUserNotificationCenter.current().add(request)
    //    }
    //    func cancelDailyReadingReminder() {
    //            UNUserNotificationCenter.current()
    //                .removePendingNotificationRequests(withIdentifiers: ["daily-reading-reminder"])
    //        }
    //}
    
    func scheduleTestReadingReminder(after seconds: TimeInterval = 18) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["test-reading-reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "책 읽을 시간이에요"
        content.body = "테스트 알림이 도착했어요."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "test-reading-reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("테스트 알림 예약 완료:", seconds, "초 뒤")
        } catch {
            print("테스트 알림 예약 실패:", error)
        }
    }
}
