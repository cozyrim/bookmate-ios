//
//  NotificationAPIService.swift
//  BookMate
//
//  Created by Codex on 6/28/26.
//

import Foundation

struct NotificationAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient()

    private struct DeviceTokenBody: Encodable {
        let token: String
        let platform: String
        let deviceId: String
        let appVersion: String
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

        let (_, response) = try await URLSession.shared.data(for: request)
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

        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"

        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)
    }
}
