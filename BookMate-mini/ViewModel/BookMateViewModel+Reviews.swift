//
//  BookMateViewModel+Reviews.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/13/26.
//
// 리뷰 조회, 저장과 다이어리 저장을 관리한다.

import Foundation

extension BookMateViewModel {
    // 현재 로그인한 사용자가 이 책에 남긴 리뷰를 찾는다.
    func myReview(for bookId: UUID) -> Review? {
        if let currentUserId {
            return reviews.first { $0.bookId == bookId && $0.ownerId == currentUserId }
        }

        return reviews.first { $0.bookId == bookId }
    }

    // 특정 책에 공개된 리뷰만 반환한다.
    func publicReviews(for bookId: UUID) -> [Review] {
        reviews.filter { $0.bookId == bookId && $0.isPublic }
    }

    // 리뷰를 서버에 저장하고 서버가 확정한 응답값으로 로컬 상태를 갱신한다.
    func saveReview(bookId: UUID, rating: Int, content: String, isPublic: Bool) async -> Bool {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("SaveReviewAPI", id: signpostID)

        defer {
            PerformanceLogger.end("SaveReviewAPI", id: signpostID)
        }

        do {
            let savedReview = try await reviewAPIService.saveReview(
                bookId: bookId,
                rating: rating,
                content: content,
                isPublic: isPublic
            )

            upsertReview(savedReview)
            operationErrorMessage = nil
            showToast("리뷰를 저장했어요.", style: .success)
            return true
        } catch {
            if handleUnauthorizedIfNeeded(error) { return false }

            operationErrorMessage = "리뷰 저장에 실패했습니다."
            showToast("리뷰 저장에 실패했어요.", style: .error)
            DebugLogger.log("리뷰 저장 실패:", error)
            return false
        }
    }

    // 리뷰 배열에 같은 id가 있으면 교체하고, 없으면 맨 앞에 추가한다.
    func upsertReview(_ review: Review) {
        if let index = reviews.firstIndex(where: { $0.id == review.id }) {
            reviews[index] = review
        } else {
            reviews.insert(review, at: 0)
        }
    }

    // 서버에서 현재 로그인한 사용자의 책 리뷰를 불러온다.
    func loadMyReview(bookId: UUID) async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("LoadMyReviewAPI", id: signpostID)

        defer {
            PerformanceLogger.end("LoadMyReviewAPI", id: signpostID)
        }

        do {
            if let review = try await reviewAPIService.fetchMyReview(bookId: bookId) {
                upsertReview(review)
            }
        } catch {
            if handleUnauthorizedIfNeeded(error) { return }

            showToast("리뷰를 불러오지 못했어요.", style: .error)
            DebugLogger.log("리뷰 조회 실패:", error)
        }
    }

    // 다이어리 폼의 별점, 감상평, 독서 상태, 읽은 기간을 책 정보에 저장한다.
    func saveRatingAndReview(
        book: Book,
        rating: Int?,
        review: String?,
        readingStatus: ReadingStatus?,
        startDate: String?,
        endDate: String?
    ) async -> Bool {
        let updatedBook = Book(
            id: book.id,
            title: book.title,
            author: book.author,
            imageName: book.imageName,
            category: book.category,
            progress: book.progress,
            totalPages: book.totalPages,
            currentPage: book.currentPage,
            rating: rating,
            review: review,
            readingStatus: readingStatus,
            startDate: startDate,
            endDate: endDate
        )
        return await updateBook(updatedBook, successMessage: "리뷰를 저장했어요.")
    }

    func loadPublicReviews(isbn: String, title: String, author: String) async {
        let signpostID = PerformanceLogger.makeSignpostID()
        PerformanceLogger.begin("LoadPublicReviewsAPI", id: signpostID)

        defer {
            PerformanceLogger.end("LoadPublicReviewsAPI", id: signpostID)
        }

        isPublicReviewLoading = true
        publicReviewErrorMessage = nil

        do {
            publicBookReviews = try await reviewAPIService.fetchPublicReviews(
                isbn: isbn,
                title: title,
                author: author
            )
        } catch {
            if handleUnauthorizedIfNeeded(error) { return }

            publicBookReviews = []
            publicReviewErrorMessage = "공개 리뷰를 불러오지 못했어요."
            DebugLogger.log("공개 리뷰 조회 실패:", error)
        }

        isPublicReviewLoading = false
    }
}
