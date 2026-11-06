import Foundation
import Combine

@MainActor
final class MyRoomViewModel: ObservableObject {
    @Published var isSurfing = false
    @Published var surfError: String?
    let guestbook: GuestbookViewModel
    private let dependencies: AppDependencies
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.guestbook = GuestbookViewModel(dependencies: dependencies)
    }
    func fetchGuestbook(user: AuthUser?) async {
        guard let token = dependencies.tokens.load(), let user else { return }
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("FetchMyGuestbookAPI", id: signpostID)
        defer { PerformanceLogger.end("FetchMyGuestbookAPI", id: signpostID) }
        do { guestbook.messages = try await dependencies.social.fetchGuestbook(token: token, userId: user.id) }
        catch { DebugLogger.log("방명록 로드 실패:", error) }
    }
    func surfRandomUser() async -> PublicUserResponse? {
        guard !isSurfing else { return nil }
        guard let token = dependencies.tokens.load() else { surfError = "로그인이 필요해요."; return nil }
        isSurfing = true
        defer { isSurfing = false }
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SurfRandomUserAPI", id: signpostID)
        defer { PerformanceLogger.end("SurfRandomUserAPI", id: signpostID) }
        do { return try await dependencies.social.getRandomUser(token: token) }
        catch { surfError = error.bookMateUserMessage(fallback: "방문할 다른 유저를 찾지 못했어요."); return nil }
    }
}
