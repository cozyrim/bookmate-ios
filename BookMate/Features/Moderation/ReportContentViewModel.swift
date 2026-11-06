import Foundation
import Combine

@MainActor
final class ReportContentViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    private let repository: any ModerationRepository

    init(repository: any ModerationRepository) { self.repository = repository }

    func submit(target: ModerationTarget, reason: ModerationReportReason, detail: String) async -> ModerationReportEnvelope? {
        guard !isSubmitting else { return nil }
        isSubmitting = true
        errorMessage = nil
        do {
            return try await repository.submitReport(target: target, reason: reason, detail: detail)
        } catch {
            errorMessage = "신고 접수에 실패했어요. 잠시 후 다시 시도해주세요."
            isSubmitting = false
            return nil
        }
    }
}
