import SwiftUI
import Combine

@MainActor
final class AppContext: ObservableObject {
    @Published var operationErrorMessage: String?
    @Published var toast: AppToast?
    @Published var didReceiveUnauthorized = false
    var currentUserId: UUID?

    func showToast(_ message: String, style: AppToast.Style = .info) {
        toast = AppToast(message: message, style: style)
    }

    func handleUnauthorizedIfNeeded(_ error: Error) -> Bool {
        if case APIError.unauthorized = error {
            didReceiveUnauthorized = true
            showToast("로그인이 만료됐어요. 다시 로그인해 주세요.", style: .error)
            return true
        }
        return false
    }
}
