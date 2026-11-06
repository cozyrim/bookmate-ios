import Foundation
import Combine

@MainActor
final class NotificationInboxViewModel: ObservableObject {
    @Published var notifications: [AppNotificationItem] = []
    @Published var isLoading = false
    @Published var unreadCount = 0
    @Published var toast: AppToast?
    private let notificationService: any NotificationRepository
    private let context: AppContext
    init(repository: any NotificationRepository, context: AppContext) {
        self.notificationService = repository
        self.context = context
    }
    func loadUnreadCount() async {
        do { unreadCount = try await notificationService.fetchUnreadCount() }
        catch { unreadCount = 0 }
    }
    @MainActor
    func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }

        do {
            notifications = try await notificationService.fetchNotifications()
        } catch {
            DebugLogger.log("알림 목록 로드 실패:", error)

            if let apiError = error as? APIError,
               case .unauthorized = apiError {
                context.didReceiveUnauthorized = true
            }
        }
    }

    @MainActor
    func markRead(_ notification: AppNotificationItem) async -> Bool {
        do {
            if !notification.isRead {
                try await notificationService.markNotificationRead(id: notification.id)
                markReadLocally(notification.id)
            }

            return true
        } catch {
            toast = AppToast(
                message: error.bookMateUserMessage(fallback: "알림을 열지 못했어요."),
                style: .error
            )
            return false
        }
    }

    @MainActor
    func markAllRead() async {
        do {
            try await notificationService.markAllNotificationsRead()
            notifications = notifications.map { notification in
                AppNotificationItem(
                    id: notification.id,
                    type: notification.type,
                    title: notification.title,
                    body: notification.body,
                    data: notification.data,
                    isRead: true,
                    createdAt: notification.createdAt,
                    readAt: notification.readAt
                )
            }
        } catch {
            toast = AppToast(
                message: error.bookMateUserMessage(fallback: "알림 상태를 바꾸지 못했어요."),
                style: .error
            )
        }
    }

    private func markReadLocally(_ id: UUID) {
        notifications = notifications.map { notification in
            guard notification.id == id else { return notification }

            return AppNotificationItem(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                isRead: true,
                createdAt: notification.createdAt,
                readAt: notification.readAt
            )
        }
    }

}
