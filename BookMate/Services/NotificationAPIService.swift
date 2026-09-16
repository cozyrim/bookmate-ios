//
//  NotificationAPIService.swift
//  BookMate
//
//  Created by Codex on 6/28/26.
//

import Foundation

struct AppNotificationItem: Decodable, Identifiable {
    let id: UUID
    let type: String
    let title: String
    let body: String
    let data: [String: String]
    let isRead: Bool
    let createdAt: String
    let readAt: String?

    var createdAtText: String {
        BookMateDateFormatter.serverDateTimeDisplayString(from: createdAt)
    }

    var userInfo: [AnyHashable: Any] {
        Dictionary(uniqueKeysWithValues: data.map { key, value in
            (AnyHashable(key), value)
        })
    }
}

struct NotificationAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient()

    private struct DeviceTokenBody: Encodable {
        let token: String
        let platform: String
        let deviceId: String
        let appVersion: String
    }

    private struct UnreadCountResponse: Decodable {
        let unreadCount: Int
    }

    func fetchNotifications() async throws -> [AppNotificationItem] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("notifications")

        let request = client.makeRequest(url: url)
        let (data, response) = try await client.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode([AppNotificationItem].self, from: data)
    }

    func fetchUnreadCount() async throws -> Int {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("notifications")
            .appendingPathComponent("unread-count")

        let request = client.makeRequest(url: url)
        let (data, response) = try await client.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode(UnreadCountResponse.self, from: data).unreadCount
    }

    func markNotificationRead(id: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("notifications")
            .appendingPathComponent(id.uuidString)
            .appendingPathComponent("read")

        let request = client.makeRequest(url: url, method: "POST")
        let (_, response) = try await client.data(for: request)
        try client.validate(response)
    }

    func markAllNotificationsRead() async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("notifications")
            .appendingPathComponent("read-all")

        let request = client.makeRequest(url: url, method: "POST")
        let (_, response) = try await client.data(for: request)
        try client.validate(response)
    }

    func upsertDeviceToken(
        token: String,
        deviceId: String,
        appVersion: String
    ) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("notifications")
            .appendingPathComponent("device-token")

        let body = DeviceTokenBody(
            token: token,
            platform: "IOS",
            deviceId: deviceId,
            appVersion: appVersion
        )

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await client.data(for: request)
        try client.validate(response)
    }

    func disableDeviceToken(token: String, accessToken: String?) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("notifications")
            .appendingPathComponent("device-token")

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]

        let request = client.makeRequest(url: components.url!, method: "DELETE", accessToken: accessToken)

        let (_, response) = try await client.data(for: request)
        try client.validate(response)
    }
}
