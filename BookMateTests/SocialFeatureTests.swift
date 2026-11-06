import XCTest
@testable import BookMate

@MainActor
final class SocialFeatureTests: XCTestCase {
    private let target = PublicUserResponse(id: UUID(), nickname: "책장 주인", profileImageUrl: nil, roomTheme: "room_bg_default")

    func testGuestbookFailureRollsBackOnlyPendingMessage() async {
        let repository = SocialRepositoryStub()
        let model = GuestbookViewModel(dependencies: dependencies(repository))
        let previous = message("기존 글")
        model.messages = [previous]

        let saved = await model.postMessage(" 새 글 ", targetUser: target, author: nil)

        XCTAssertFalse(saved)
        XCTAssertEqual(model.messages.map(\.id), [previous.id])
        XCTAssertTrue(model.pendingMessageIDs.isEmpty)
        XCTAssertFalse(model.isPosting)
        XCTAssertNotNil(model.toast)
    }

    func testGuestbookShowsPendingMessageThenUsesServerIdentity() async {
        let repository = SocialRepositoryStub()
        repository.suspendWrite = true
        let model = GuestbookViewModel(dependencies: dependencies(repository))
        let task = Task { await model.postMessage(" 새 글 ", targetUser: target, author: nil) }
        await repository.waitForWrite()
        let pendingID = model.messages.first?.id
        XCTAssertEqual(model.messages.first?.content, "새 글")
        XCTAssertEqual(model.pendingMessageIDs.first, pendingID)
        XCTAssertTrue(model.isPosting)
        let response = message("새 글")

        repository.finishWrite(response)
        let saved = await task.value

        XCTAssertTrue(saved)
        XCTAssertEqual(repository.writtenContent, "새 글")
        XCTAssertEqual(repository.writtenTargetID, target.id)
        XCTAssertEqual(model.messages.map(\.id), [response.id])
        XCTAssertNotEqual(response.id, pendingID)
        XCTAssertTrue(model.pendingMessageIDs.isEmpty)
        XCTAssertFalse(model.isPosting)
    }

    func testBlankGuestbookInputDoesNotWriteOrChangeMessages() async {
        let repository = SocialRepositoryStub()
        let model = GuestbookViewModel(dependencies: dependencies(repository))

        let saved = await model.postMessage(" \n ", targetUser: target, author: nil)

        XCTAssertFalse(saved)
        XCTAssertEqual(repository.writeCount, 0)
        XCTAssertTrue(model.messages.isEmpty)
    }

    func testUserSearchFiltersBlockedUsers() async {
        let repository = SocialRepositoryStub()
        let blocked = PublicUserResponse(id: UUID(), nickname: "차단", profileImageUrl: nil, roomTheme: "room_bg_default")
        repository.users = [target, blocked]
        let model = UserSearchViewModel(dependencies: dependencies(repository))
        model.blockedUserIDs = [blocked.id]
        model.searchText = "책장"

        await model.performSearch(query: "책장")

        XCTAssertEqual(model.searchResults, [target])
        XCTAssertFalse(model.isSearching)
    }

    func testFailedBlockLeavesPublicRoomOpenableAndEndsLoading() async {
        let model = PublicBookshelfViewModel(targetUser: target, dependencies: dependencies(SocialRepositoryStub()))

        let blocked = await model.blockTargetUser()

        XCTAssertFalse(blocked)
        XCTAssertFalse(model.isBlocking)
        XCTAssertNotNil(model.toast)
    }

    func testSurfingWithoutCredentialsDoesNotRequestRandomUser() async {
        let repository = SocialRepositoryStub()
        let model = MyRoomViewModel(dependencies: AppDependencies(social: repository, tokens: SocialTokens(token: nil)))

        let result = await model.surfRandomUser()

        XCTAssertNil(result)
        XCTAssertEqual(repository.randomRequests, 0)
        XCTAssertEqual(model.surfError, "로그인이 필요해요.")
    }

    private func dependencies(_ repository: SocialRepositoryStub) -> AppDependencies {
        AppDependencies(social: repository, moderation: ModerationRepositoryStub(), tokens: SocialTokens(token: "test-token"))
    }
    private func message(_ content: String) -> GuestbookMessageResponse {
        GuestbookMessageResponse(id: UUID(), writerId: UUID(), writerNickname: "작성자", writerProfileImageUrl: nil, content: content, createdAt: "2026-01-01T00:00:00.000")
    }
}

private enum SocialStubError: Error { case rejected }

@MainActor
private final class SocialTokens: AuthTokenStore {
    private var token: String?
    init(token: String?) { self.token = token }
    func save(_ token: String) { self.token = token }
    func load() -> String? { token }
    func clear() { token = nil }
    func save(accessToken: String, refreshToken: String) { token = accessToken }
    func loadRefreshToken() -> String? { nil }
    func replace(expectedRefreshToken: String, accessToken: String, refreshToken: String) -> Bool { false }
}

@MainActor
private final class SocialRepositoryStub: SocialRepository {
    var users: [PublicUserResponse] = []
    var randomRequests = 0
    var writeCount = 0
    var writtenContent: String?
    var writtenTargetID: UUID?
    var suspendWrite = false
    private var pendingWrite: CheckedContinuation<GuestbookMessageResponse, Error>?
    private var arrival: CheckedContinuation<Void, Never>?
    func searchUsers(token: String, nickname: String) async throws -> [PublicUserResponse] { users }
    func getRandomUser(token: String) async throws -> PublicUserResponse { randomRequests += 1; throw SocialStubError.rejected }
    func fetchPublicBooks(token: String, userId: UUID) async throws -> [Book] { throw SocialStubError.rejected }
    func fetchGuestbook(token: String, userId: UUID) async throws -> [GuestbookMessageResponse] { throw SocialStubError.rejected }
    func writeGuestbook(token: String, userId: UUID, content: String) async throws -> GuestbookMessageResponse {
        writeCount += 1
        writtenContent = content
        writtenTargetID = userId
        guard suspendWrite else { throw SocialStubError.rejected }
        return try await withCheckedThrowingContinuation { pendingWrite = $0; arrival?.resume(); arrival = nil }
    }
    func deleteGuestbook(token: String, messageId: UUID) async throws { throw SocialStubError.rejected }
    func waitForWrite() async {
        if pendingWrite != nil { return }
        await withCheckedContinuation { arrival = $0 }
    }
    func finishWrite(_ message: GuestbookMessageResponse) {
        pendingWrite?.resume(returning: message)
        pendingWrite = nil
    }
}

@MainActor
private final class ModerationRepositoryStub: ModerationRepository {
    func submitReport(target: ModerationTarget, reason: ModerationReportReason, detail: String?) async throws -> ModerationReportEnvelope { throw SocialStubError.rejected }
    func blockUser(userId: UUID) async throws -> UserBlockResponse { throw SocialStubError.rejected }
    func unblockUser(userId: UUID) async throws { throw SocialStubError.rejected }
    func fetchBlockedUsers() async throws -> [UserBlockResponse] { [] }
    func checkContent(_ content: String, context: ContentModerationContext) async throws -> ContentCheckResponse { throw SocialStubError.rejected }
}
