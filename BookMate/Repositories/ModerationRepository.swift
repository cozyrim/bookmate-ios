import Foundation

protocol ModerationRepository {
    func submitReport(
            target: ModerationTarget,
            reason: ModerationReportReason,
            detail: String?
        ) async throws -> ModerationReportEnvelope
    func blockUser(userId: UUID) async throws -> UserBlockResponse
    func unblockUser(userId: UUID) async throws
    func fetchBlockedUsers() async throws -> [UserBlockResponse]
    func checkContent(
            _ content: String,
            context: ContentModerationContext
        ) async throws -> ContentCheckResponse
}
