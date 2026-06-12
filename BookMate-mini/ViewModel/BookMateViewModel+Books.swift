//
//  BookMateViewModel+Books.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/13/26.
//
// 책 등록, 조회, 수정, 삭제와 책장 표시용 데이터를 관리한다.

import Foundation

extension BookMateViewModel {
    // 서버에서 내 책 목록을 불러오고 책장 표시용 상태를 동기화한다.
    func loadBooks() async {
        do {
            books = try await bookAPIService.fetchBooks()
            syncShelfBooksFromBooks()
            bookLoadErrorMessage = nil
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                bookLoadErrorMessage = nil
                return
            }

            bookLoadErrorMessage = "책 목록을 불러오지 못했습니다."
            DebugLogger.log("책 목록 조회 실패:", error)
        }
    }

    // 카카오 책 검색 API로 등록할 책 후보를 찾는다.
    func searchBooks(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            bookSearchErrorMessage = "책 제목 또는 저자를 입력해 주세요."
            return
        }

        isBookSearchLoading = true
        bookSearchErrorMessage = nil

        do {
            bookSearchResults = try await kakaoBookSearchService.searchBooks(query: trimmed)
        } catch {
            bookSearchResults = []
            bookSearchErrorMessage = "책 검색에 실패했습니다."
            DebugLogger.log("책 검색 실패:", error)
        }
        isBookSearchLoading = false
    }

    // 등록 초안으로 서버에 새 책을 저장하고 화면 상태에 즉시 반영한다.
    func registerBook(draft: BookRegistrationDraft) async throws -> Book {
        do {
            let totalPages: Int?
            if let draftTotalPages = draft.totalPages {
                totalPages = draftTotalPages
            } else {
                totalPages = await bookPageLookupService.fetchPageCount(isbn: draft.isbn)
            }

            let savedBook = try await bookAPIService.createBook(
                title: draft.title,
                author: draft.author,
                imageName: draft.imageName,
                category: draft.category,
                progress: draft.progress,
                totalPages: totalPages,
                currentPage: totalPages == nil ? nil : 0
            )
            books.insert(savedBook, at: 0)
            syncShelfBooksFromBooks()
            operationErrorMessage = nil
            showToast("책을 등록했어요.", style: .success)
            return savedBook
        } catch {
            if handleUnauthorizedIfNeeded(error) {
                throw error
            }

            operationErrorMessage = "책 등록에 실패했습니다."
            showToast("책 등록에 실패했어요.", style: .error)
            DebugLogger.log("책 등록 실패:", error)
            throw error
        }
    }

    // 서버에서 책을 삭제하고 관련 로컬 상태도 함께 제거한다.
    func deleteBook(_ book: Book) async -> Bool {
        do {
            try await bookAPIService.deleteBook(id: book.id)

            books.removeAll { $0.id == book.id }
            savedWords.removeAll { $0.bookId == book.id }
            shelfBooks.removeAll { $0.bookId == book.id }

            operationErrorMessage = nil
            showToast("책을 삭제했어요.", style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "책 삭제에 실패했습니다."
            showToast("책 삭제에 실패했어요.", style: .error)
            DebugLogger.log("책 삭제 실패:", error)
            return false
        }
    }

    // 책 정보와 독서 상태를 서버에 수정 요청하고 로컬 상태를 갱신한다.
    func updateBook(_ book: Book, successMessage: String = "책 정보를 수정했어요.") async -> Bool {
        if isRunningForPreview {
            if let index = books.firstIndex(where: { $0.id == book.id }) {
                books[index] = book
            }
            operationErrorMessage = nil
            showToast(successMessage, style: .success)
            return true
        }

        do {
            let updatedBook = try await bookAPIService.updateBook(book)

            if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
                books[index] = updatedBook

                if let shelfIndex = shelfBooks.firstIndex(where: { $0.bookId == updatedBook.id }) {
                    shelfBooks[shelfIndex].progress = updatedBook.progress
                    shelfBooks[shelfIndex].status = updatedBook.readingStatus ?? shelfBooks[shelfIndex].status
                    shelfBooks[shelfIndex].updatedAt = Date()
                }
            }

            operationErrorMessage = nil
            showToast(successMessage, style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "책 수정에 실패했습니다."
            showToast("책 수정에 실패했어요.", style: .error)
            DebugLogger.log("책 수정 실패:", error)
            return false
        }
    }

    // ISBN으로 페이지 수를 조회해 책 등록 폼의 페이지 값을 자동 입력한다.
    func lookupBookPageCount(isbn: String) async -> Int? {
        await bookPageLookupService.fetchPageCount(isbn: isbn)
    }

    // 책장 카드가 참조하는 ShelfBook에 해당하는 책 정보를 찾는다.
    func book(for shelfBook: ShelfBook) -> Book? {
        books.first { $0.id == shelfBook.bookId }
    }

    // 상세 화면 이동 시 bookId에 해당하는 책 정보를 찾는다.
    func book(for bookId: UUID) -> Book? {
        books.first { $0.id == bookId }
    }

    // 진행률, 공개 여부, 독서 상태 표시를 위해 책장 상태를 찾는다.
    func shelfBook(for bookId: UUID) -> ShelfBook? {
        shelfBooks.first { $0.bookId == bookId }
    }

    // REST Book 데이터를 책장 렌더링용 ShelfBook 상태로 변환한다.
    private func makeShelfBook(from book: Book) -> ShelfBook {
        ShelfBook(
            id: "shelf-\(book.id.uuidString)",
            ownerId: "current-user",
            bookId: book.id,
            progress: book.progress,
            status: book.readingStatus ?? .reading,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // books 배열을 기준으로 shelfBooks를 다시 만든다.
    private func syncShelfBooksFromBooks() {
        shelfBooks = books.map { book in
            makeShelfBook(from: book)
        }
    }

    // 책장에 표시할 Book 목록을 ShelfBook 순서에 맞춰 만든다.
    var booksOnShelf: [Book] {
        shelfBooks.compactMap { shelfBook in
            book(for: shelfBook)
        }
    }

    // 현재 선택된 카테고리에 속한 책 목록을 반환한다.
    var booksInSelectedCategory: [Book] {
        guard let category = archiveSelectedCategory else {
            return booksOnShelf
        }
        return books.filter { $0.category == category }
    }

    // Xcode Preview 실행 여부를 확인해 네트워크 요청을 피한다.
    private var isRunningForPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
