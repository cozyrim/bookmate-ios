//
//  PushNotificationRouter.swift
//  BookMate
//
//  Created by Codex on 6/29/26.
//

import Combine
import Foundation

struct PushNotificationNavigationRequest: Identifiable, Equatable {
    let id: UUID
    let destination: PushNotificationDestination

    init(destination: PushNotificationDestination, id: UUID = UUID()) {
        self.id = id
        self.destination = destination
    }
}

enum PushNotificationDestination: Equatable {
    case myGuestbook(messageId: UUID?)

    init?(userInfo: [AnyHashable: Any]) {
        guard let type = Self.stringValue(userInfo["type"]) else {
            return nil
        }

        switch type {
        case "guestbook_message":
            self = .myGuestbook(messageId: Self.uuidValue(userInfo["message_id"]))
        default:
            return nil
        }
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let value as String:
            return value
        case let value as CustomStringConvertible:
            return value.description
        default:
            return nil
        }
    }

    private static func uuidValue(_ value: Any?) -> UUID? {
        guard let string = stringValue(value) else {
            return nil
        }

        return UUID(uuidString: string)
    }
}

@MainActor
final class PushNotificationRouter: ObservableObject {
    static let shared = PushNotificationRouter()

    @Published private(set) var pendingRequest: PushNotificationNavigationRequest?

    private init() {}

    func route(userInfo: [AnyHashable: Any]) {
        guard let destination = PushNotificationDestination(userInfo: userInfo) else {
            DebugLogger.log("처리할 수 없는 알림 payload:", userInfo)
            return
        }

        pendingRequest = PushNotificationNavigationRequest(destination: destination)
    }

    func consume(_ request: PushNotificationNavigationRequest) {
        guard pendingRequest?.id == request.id else {
            return
        }

        pendingRequest = nil
    }
}
