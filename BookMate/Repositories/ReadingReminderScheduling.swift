import Foundation

protocol ReadingReminderScheduling {
    func scheduleContinueReadingReminderIfEnabled(book: Book?, shelfBook: ShelfBook?) async
}

extension ReadingNotificationService: ReadingReminderScheduling {}
