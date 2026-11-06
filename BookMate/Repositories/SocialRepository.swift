import Foundation

protocol SocialRepository {
    func searchUsers(token: String, nickname: String) async throws -> [PublicUserResponse]
    func getRandomUser(token: String) async throws -> PublicUserResponse
    func fetchPublicBooks(token: String, userId: UUID) async throws -> [Book]
    func fetchGuestbook(token: String, userId: UUID) async throws -> [GuestbookMessageResponse]
    func writeGuestbook(token: String, userId: UUID, content: String) async throws -> GuestbookMessageResponse
    func deleteGuestbook(token: String, messageId: UUID) async throws
}
