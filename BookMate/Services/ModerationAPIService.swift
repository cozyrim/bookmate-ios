//
//  ModerationAPIService.swift
//  BookMate
//
//  Created by Codex on 6/20/26.
//

import Foundation

struct ModerationAPIService {
    private let baseURL = APIEnvironment.baseURL
    private let client = APIClient()

    func submitReport(
        target: ModerationTarget,
        reason: ModerationReportReason,
        detail: String?
    ) async throws -> ModerationReportEnvelope {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("moderation")
            .appendingPathComponent("reports")

        let body = ModerationReportRequest(
            targetType: target.targetType,
            targetId: target.targetId,
            targetUserId: target.targetUserId?.uuidString,
            reason: reason,
            detail: detail?.trimmingCharacters(in: .whitespacesAndNewlines),
            targetSnapshot: target.snapshot.isEmpty ? nil : target.snapshot
        )

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode(ModerationReportEnvelope.self, from: data)
    }

    func blockUser(userId: UUID) async throws -> UserBlockResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("moderation")
            .appendingPathComponent("blocks")

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(BlockUserRequest(blockedUserId: userId.uuidString))

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode(UserBlockResponse.self, from: data)
    }

    func unblockUser(userId: UUID) async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("moderation")
            .appendingPathComponent("blocks")
            .appendingPathComponent(userId.uuidString)

        let request = client.makeRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)
    }

    func fetchBlockedUsers() async throws -> [UserBlockResponse] {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("moderation")
            .appendingPathComponent("blocks")

        let request = client.makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode([UserBlockResponse].self, from: data)
    }

    func checkContent(
        _ content: String,
        context: ContentModerationContext
    ) async throws -> ContentCheckResponse {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("moderation")
            .appendingPathComponent("content")
            .appendingPathComponent("check")

        var request = client.makeRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ContentCheckRequest(content: content, context: context)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try client.validate(response)

        return try JSONDecoder().decode(ContentCheckResponse.self, from: data)
    }
}
