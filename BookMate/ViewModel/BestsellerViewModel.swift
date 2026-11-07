import Foundation
import Combine

@MainActor
final class BestsellerViewModel: ObservableObject {
    @Published private(set) var feed: BestsellerFeed?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    private let repository: any BestsellerRepository

    init(repository: any BestsellerRepository) { self.repository = repository }

    var updatedTimeText: String {
        guard let text = feed?.fetchedAt,
              let date = ISO8601DateFormatter().date(from: text) ?? Self.fractionalDate(text) else { return "최근" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private static func fractionalDate(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: text)
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await repository.fetchRealtime()
            try Task.checkCancellation()
            feed = result
        } catch {
            guard !Task.isCancelled else { return }
            feed = nil
            errorMessage = "베스트셀러를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}
