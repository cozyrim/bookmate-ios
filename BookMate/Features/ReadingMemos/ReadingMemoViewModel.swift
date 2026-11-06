import Foundation
import Combine

@MainActor
final class ReadingMemoViewModel: ObservableObject {
    @Published var readingMemos: [ReadingMemo] = []

    private let memoRepository: any ReadingMemoRepository
    private let context: AppContext

    init(repository: any ReadingMemoRepository, context: AppContext) {
        self.memoRepository = repository
        self.context = context
    }

    // 메모리에 있는 독서 메모 중 특정 책에 속한 메모만 반환한다.
    func savedMemos(for bookId: UUID) -> [ReadingMemo] {
        readingMemos.filter { $0.bookId == bookId }
    }

    // 특정 책의 독서 메모 목록을 서버에서 불러온다.
    func loadReadingMemos(bookId: UUID) async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("LoadReadingMemosAPI", id: signpostID)

        defer {
            PerformanceLogger.end("LoadReadingMemosAPI", id: signpostID)
        }

        do {
            readingMemos = try await memoRepository.fetchMemos(bookId: bookId)
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return }
            DebugLogger.log("메모 불러오기 실패:", error)
        }
    }

    // 새 독서 메모를 서버에 저장하고 날짜순으로 정렬한다.
    func saveReadingMemo(bookId: UUID, date: String, page: Int?, text: String) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SaveReadingMemoAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SaveReadingMemoAPI", id: signpostID)
        }

        do {
            let savedMemo = try await memoRepository.saveMemo(bookId: bookId, date: date, page: page, text: text)
            readingMemos.append(savedMemo)
            sortReadingMemosByDate()
            context.showToast("메모를 기록했어요.", style: .success)
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }
            context.showToast("메모 저장에 실패했어요.", style: .error)
            DebugLogger.log("메모 저장 실패:", error)
            return false
        }
    }

    // 기존 독서 메모를 서버에 수정 요청하고 로컬 목록을 갱신한다.
    func updateReadingMemo(_ memo: ReadingMemo) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("UpdateReadingMemoAPI", id: signpostID)

        defer {
            PerformanceLogger.end("UpdateReadingMemoAPI", id: signpostID)
        }

        do {
            let updatedMemo = try await memoRepository.updateMemo(memo)
            if let index = readingMemos.firstIndex(where: { $0.id == memo.id }) {
                readingMemos[index] = updatedMemo
                sortReadingMemosByDate()
            }
            context.showToast("메모가 수정되었어요.", style: .success)
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }
            context.showToast("메모 수정에 실패했어요.", style: .error)
            DebugLogger.log("메모 수정 실패:", error)
            return false
        }
    }

    // 서버에서 독서 메모를 삭제하고 로컬 목록에서도 제거한다.
    func deleteReadingMemo(_ memo: ReadingMemo) async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("DeleteReadingMemoAPI", id: signpostID)

        defer {
            PerformanceLogger.end("DeleteReadingMemoAPI", id: signpostID)
        }

        do {
            try await memoRepository.deleteMemo(id: memo.id)
            readingMemos.removeAll { $0.id == memo.id }
            context.showToast("메모가 삭제되었어요.", style: .success)
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return }
            context.showToast("메모 삭제에 실패했어요.", style: .error)
            DebugLogger.log("메모 삭제 실패:", error)
        }
    }

    // 독서 메모를 날짜 오름차순으로 정렬한다.
    private func sortReadingMemosByDate() {
        readingMemos.sort { $0.date < $1.date }
    }
}
