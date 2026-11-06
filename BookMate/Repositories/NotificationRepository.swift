import Foundation

protocol NotificationRepository {
    func fetchNotifications() async throws -> [AppNotificationItem]
    func fetchUnreadCount() async throws -> Int
    func markNotificationRead(id: UUID) async throws
    func markAllNotificationsRead() async throws
}
