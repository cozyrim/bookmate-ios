//
//  BookMateDateFormatter.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/13/26.
//

import Foundation

enum BookMateDateFormatter {
    static let api: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    static let dateTimeDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    static func apiString(from date: Date?) -> String? {
        guard let date else { return nil }
        return api.string(from: date)
    }

    static func displayString(from date: Date?) -> String {
        guard let date else { return "날짜 선택" }
        return display.string(from: date)
    }

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return api.date(from: string) ?? display.date(from: string)
    }

    static func serverDateTime(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    static func reviewDisplayString(from date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "오늘"
        }

        if calendar.isDateInYesterday(date) {
            return "어제"
        }

        return display.string(from: date)
    }

    static func serverDateTimeDisplayString(from string: String?) -> String {
        guard let string, !string.isEmpty else { return "" }

        if let date = serverDateTime(from: string) {
            return dateTimeDisplay.string(from: date)
        }

        return string
            .replacingOccurrences(of: "T", with: " ")
            .split(separator: ".")
            .first
            .map(String.init) ?? string
    }
}
