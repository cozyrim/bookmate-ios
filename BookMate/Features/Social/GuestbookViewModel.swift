import Foundation
import Combine

@MainActor
final class GuestbookViewModel: ObservableObject {
    @Published var messages: [GuestbookMessageResponse] = []
    @Published var isPosting = false
    @Published var pendingMessageIDs: Set<UUID> = []
    @Published var toast: AppToast?
    let dependencies: AppDependencies
    private var socialService: any SocialRepository { dependencies.social }
    var moderationService: any ModerationRepository { dependencies.moderation }
    private var tokenStore: any AuthTokenStore { dependencies.tokens }
    init(dependencies: AppDependencies) { self.dependencies = dependencies }
    @MainActor
    func postMessage(_ content: String, targetUser: PublicUserResponse, author: AuthUser?) async -> Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let token = tokenStore.load(), !trimmedContent.isEmpty else { return false }

        let totalSignpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("PostGuestbookTotal", id: totalSignpostID)

        isPosting = true

        let optimisticMessage = makeOptimisticMessage(content: trimmedContent, author: author)
        let optimisticSignpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("PostGuestbookOptimisticUI", id: optimisticSignpostID)
        pendingMessageIDs.insert(optimisticMessage.id)
        messages.insert(optimisticMessage, at: 0)
        PerformanceLogger.end("PostGuestbookOptimisticUI", id: optimisticSignpostID)

        defer {
            isPosting = false
            PerformanceLogger.end("PostGuestbookTotal", id: totalSignpostID)
        }

        do {
            let apiSignpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("PostGuestbookAPI", id: apiSignpostID)
            defer {
                PerformanceLogger.end("PostGuestbookAPI", id: apiSignpostID)
            }

            let newMessage = try await socialService.writeGuestbook(
                token: token,
                userId: targetUser.id,
                content: trimmedContent
            )

            replaceOptimisticMessage(id: optimisticMessage.id, with: newMessage)
            return true
        } catch {
            pendingMessageIDs.remove(optimisticMessage.id)
            messages.removeAll { $0.id == optimisticMessage.id }
            print("방명록 작성 실패: \(error)")
            toast = AppToast(message: "방명록 작성에 실패했어요.", style: .error)
            return false
        }
    }

    private func makeOptimisticMessage(content: String, author: AuthUser?) -> GuestbookMessageResponse {
        GuestbookMessageResponse(
            id: UUID(),
            writerId: author?.id ?? UUID(),
            writerNickname: author?.nickname ?? "나",
            writerProfileImageUrl: author?.profileImageUrl,
            content: content,
            createdAt: pendingCreatedAtString()
        )
    }

    private func replaceOptimisticMessage(id: UUID, with message: GuestbookMessageResponse) {
        pendingMessageIDs.remove(id)

        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            messages.insert(message, at: 0)
            return
        }

        messages[index] = message
    }

    private func pendingCreatedAtString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date())
    }

    func deleteMessage(messageId: UUID) {
        guard let token = tokenStore.load() else { return }

        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("DeleteGuestbookAPI", id: signpostID)

            defer {
                PerformanceLogger.end("DeleteGuestbookAPI", id: signpostID)
            }

            do {
                try await socialService.deleteGuestbook(token: token, messageId: messageId)
                await MainActor.run {
                    messages.removeAll { $0.id == messageId }
                    toast = AppToast(message: "방명록을 삭제했어요.", style: .success)
                }
            } catch {
                print("방명록 삭제 실패: \(error)")
                await MainActor.run {
                    toast = AppToast(message: "방명록 삭제에 실패했어요.", style: .error)
                }
            }
        }
    }

    func blockWriter(of message: GuestbookMessageResponse) {

        Task {
            do {
                _ = try await moderationService.blockUser(userId: message.writerId)

                await MainActor.run {
                    messages.removeAll { $0.writerId == message.writerId }
                    toast = AppToast(message: "\(message.writerNickname)님을 차단했어요.", style: .success)
                }
            } catch {
                await MainActor.run {
                    toast = AppToast(message: "차단에 실패했어요.", style: .error)
                }
            }
        }
    }

    func hideReportedContent(_ result: ModerationReportEnvelope) {
        if result.report.targetType == .guestbookMessage,
           let messageId = UUID(uuidString: result.report.targetId) {
            messages.removeAll { $0.id == messageId }
        }
    }
}
