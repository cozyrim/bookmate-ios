#if DEBUG
import Foundation

@MainActor
final class UIFixtureNotifications: NotificationRepository {
    private var items = [AppNotificationItem(id: UUID(), type: "guestbook_message", title: "새 방명록", body: "서재 친구가 글을 남겼어요.", data: ["type": "guestbook_message", "message_id": UIFixtureSocial.messageID.uuidString], isRead: false, createdAt: "2026-01-01T00:00:00.000", readAt: nil)]
    func fetchNotifications() async throws -> [AppNotificationItem] { items }
    func fetchUnreadCount() async throws -> Int { items.filter { !$0.isRead }.count }
    func markNotificationRead(id: UUID) async throws { markRead(ids: [id]) }
    func markAllNotificationsRead() async throws { markRead(ids: Set(items.map(\.id))) }
    private func markRead(ids: Set<UUID>) {
        items = items.map { item in
            guard ids.contains(item.id) else { return item }
            return AppNotificationItem(id: item.id, type: item.type, title: item.title, body: item.body, data: item.data, isRead: true, createdAt: item.createdAt, readAt: item.readAt)
        }
    }
}
#endif
