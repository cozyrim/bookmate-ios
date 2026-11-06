import XCTest
@testable import BookMate

@MainActor
final class NotificationFeatureTests: XCTestCase {
    func testUnauthorizedLoadPreservesPreviousListAndEndsLoading() async {
        let repository = NotificationRepositoryStub()
        repository.error = APIError.unauthorized
        let context = AppContext()
        let model = NotificationInboxViewModel(repository: repository, context: context)
        let previous = notification()
        model.notifications = [previous]

        await model.loadNotifications()

        XCTAssertEqual(model.notifications.map(\.id), [previous.id])
        XCTAssertTrue(context.didReceiveUnauthorized)
        XCTAssertFalse(model.isLoading)
    }

    func testReadUpdatesOnlyTheConfirmedNotification() async {
        let repository = NotificationRepositoryStub()
        let model = NotificationInboxViewModel(repository: repository, context: AppContext())
        let first = notification()
        let second = notification()
        model.notifications = [first, second]

        let opened = await model.markRead(first)

        XCTAssertTrue(opened)
        XCTAssertEqual(repository.markedIDs, [first.id])
        XCTAssertTrue(model.notifications[0].isRead)
        XCTAssertFalse(model.notifications[1].isRead)
        XCTAssertEqual(model.notifications[0].data, first.data)
    }

    func testReadFailureDoesNotMarkReadOrAllowNavigation() async {
        let repository = NotificationRepositoryStub()
        repository.error = URLError(.notConnectedToInternet)
        let model = NotificationInboxViewModel(repository: repository, context: AppContext())
        let previous = notification()
        model.notifications = [previous]

        let opened = await model.markRead(previous)

        XCTAssertFalse(opened)
        XCTAssertFalse(model.notifications[0].isRead)
        XCTAssertNotNil(model.toast)
    }

    func testAlreadyReadNotificationNeedsNoRemoteMutation() async {
        let repository = NotificationRepositoryStub()
        let model = NotificationInboxViewModel(repository: repository, context: AppContext())

        let opened = await model.markRead(notification(isRead: true))

        XCTAssertTrue(opened)
        XCTAssertTrue(repository.markedIDs.isEmpty)
    }

    private func notification(isRead: Bool = false) -> AppNotificationItem {
        AppNotificationItem(id: UUID(), type: "guestbook", title: "알림", body: "내용", data: ["messageId": "test"], isRead: isRead, createdAt: "2026-01-01T00:00:00", readAt: nil)
    }
}

@MainActor
private final class NotificationRepositoryStub: NotificationRepository {
    var error: Error?
    var markedIDs: [UUID] = []
    func fetchNotifications() async throws -> [AppNotificationItem] {
        if let error { throw error }
        return []
    }
    func fetchUnreadCount() async throws -> Int { 0 }
    func markNotificationRead(id: UUID) async throws {
        if let error { throw error }
        markedIDs.append(id)
    }
    func markAllNotificationsRead() async throws {
        if let error { throw error }
    }
}
