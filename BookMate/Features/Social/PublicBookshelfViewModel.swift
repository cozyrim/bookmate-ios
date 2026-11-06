import Foundation
import Combine

@MainActor
final class PublicBookshelfViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var isBlocking = false
    @Published var toast: AppToast?
    let guestbook: GuestbookViewModel
    let targetUser: PublicUserResponse
    let dependencies: AppDependencies
    private var socialService: any SocialRepository { dependencies.social }
    private var tokenStore: any AuthTokenStore { dependencies.tokens }
    init(targetUser: PublicUserResponse, dependencies: AppDependencies) {
        self.targetUser = targetUser
        self.dependencies = dependencies
        self.guestbook = GuestbookViewModel(dependencies: dependencies)
    }
    func fetchData() {
        guard let token = tokenStore.load() else { return }
        isLoading = true

        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("FetchPublicBookshelfAPI", id: signpostID)

            defer {
                PerformanceLogger.end("FetchPublicBookshelfAPI", id: signpostID)
            }

            do {
                async let fetchedBooks = socialService.fetchPublicBooks(token: token, userId: targetUser.id)
                async let fetchedMessages = socialService.fetchGuestbook(token: token, userId: targetUser.id)

                let (bookResult, messageResult) = try await (fetchedBooks, fetchedMessages)

                await MainActor.run {
                    books = bookResult
                    guestbook.messages = messageResult
                    isLoading = false
                }
            } catch {
                print("로드 실패: \(error)")
                await MainActor.run {
                    isLoading = false
                    toast = AppToast(message: "공개 책장을 불러오지 못했어요.", style: .error)
                }
            }
        }
    }

    func blockTargetUser() async -> Bool {
        guard !isBlocking else { return false }
        isBlocking = true
        defer { isBlocking = false }
        do {
            _ = try await dependencies.moderation.blockUser(userId: targetUser.id)
            toast = AppToast(message: "\(targetUser.nickname)님을 차단했어요.", style: .success)
            return true
        } catch {
            toast = AppToast(message: "차단에 실패했어요.", style: .error)
            return false
        }
    }
}
