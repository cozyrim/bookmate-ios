import Foundation
import Combine

@MainActor
final class BookRegistrationViewModel: ObservableObject {
    @Published var savedBook: Book?
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var aladinDescription: String?
    private let library: BookLibraryViewModel
    private let metadata: any BookMetadataRepository

    init(library: BookLibraryViewModel, metadata: any BookMetadataRepository) {
        self.library = library
        self.metadata = metadata
    }

    func register(draft: BookRegistrationDraft) async {
        guard !isSaving else { return }
        savedBook = nil
        var normalized = draft
        normalized.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.author = draft.author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.title.isEmpty, !normalized.author.isEmpty else {
            errorMessage = "책 제목과 저자를 입력해주세요."
            return
        }
        if let pages = normalized.totalPages, pages <= 0 {
            errorMessage = "전체 쪽수는 1 이상으로 입력해주세요."
            return
        }
        if normalized.category.isEmpty || normalized.category == "카테고리 선택" {
            normalized.category = "기타"
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do { savedBook = try await library.registerBook(draft: normalized) }
        catch BookRegistrationError.duplicate { errorMessage = nil }
        catch {
            errorMessage = "책 등록에 실패했습니다."
            DebugLogger.log("책 등록 실패:", error)
        }
    }

    func lookupPageCount(isbn: String) async -> Int? {
        await library.lookupBookPageCount(isbn: isbn)
    }

    func loadDescription(isbn: String) async {
        guard !isbn.isEmpty else { return }
        if let result = await metadata.fetchMetadata(isbn: isbn),
           let description = result.description,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !Task.isCancelled {
            aladinDescription = description
        }
    }
}
