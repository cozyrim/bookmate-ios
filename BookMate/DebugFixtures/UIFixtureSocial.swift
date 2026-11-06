#if DEBUG
import Foundation

@MainActor
final class UIFixtureSocial: SocialRepository, ModerationRepository {
    static let messageID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    let friend = PublicUserResponse(id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!, nickname: "서재 친구", profileImageUrl: nil, roomTheme: "room_bg_default")
    var messages = [GuestbookMessageResponse(id: messageID, writerId: UUID(), writerNickname: "서재 친구", writerProfileImageUrl: nil, content: "좋은 책장을 구경했어요.", createdAt: "2026-01-01T00:00:00.000")]
    func searchUsers(token: String, nickname: String) async throws -> [PublicUserResponse] {
        return [friend]
    }
    func getRandomUser(token: String) async throws -> PublicUserResponse {
        return friend
    }
    func fetchPublicBooks(token: String, userId: UUID) async throws -> [Book] {
        return [Book.dummyBooks[0]]
    }
    func fetchGuestbook(token: String, userId: UUID) async throws -> [GuestbookMessageResponse] {
        return messages
    }
    func writeGuestbook(token: String, userId: UUID, content: String) async throws -> GuestbookMessageResponse {
        let message = GuestbookMessageResponse(id: UUID(), writerId: UIFixtureAuth.userID, writerNickname: "독서가", writerProfileImageUrl: nil, content: content, createdAt: "2026-01-01T00:00:00.000"); messages.insert(message, at: 0); return message
    }
    func deleteGuestbook(token: String, messageId: UUID) async throws {
        messages.removeAll { $0.id == messageId }
    }
    func submitReport(
            target: ModerationTarget,
            reason: ModerationReportReason,
            detail: String?
        ) async throws -> ModerationReportEnvelope {
        throw URLError(.resourceUnavailable)
    }
    func blockUser(userId: UUID) async throws -> UserBlockResponse {
        throw URLError(.resourceUnavailable)
    }
    func unblockUser(userId: UUID) async throws {
        throw URLError(.resourceUnavailable)
    }
    func fetchBlockedUsers() async throws -> [UserBlockResponse] {
        return []
    }
    func checkContent(
            _ content: String,
            context: ContentModerationContext
        ) async throws -> ContentCheckResponse {
        throw URLError(.resourceUnavailable)
    }
}
#endif
