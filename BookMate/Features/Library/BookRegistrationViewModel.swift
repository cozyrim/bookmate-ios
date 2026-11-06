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
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do { savedBook = try await library.registerBook(draft: draft) }
        catch BookRegistrationError.duplicate { errorMessage = nil }
        catch {
            errorMessage = "책 등록에 실패했습니다."
            DebugLogger.log("책 등록 실패:", error)
        }
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
