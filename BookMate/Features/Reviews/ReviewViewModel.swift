import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = Review.sampleReviews
    @Published var publicBookReviews: [Review] = []
    @Published var isPublicReviewLoading: Bool = false
    @Published var publicReviewErrorMessage: String?

    private let reviewRepository: any ReviewRepository
    private let context: AppContext

    init(repository: any ReviewRepository, context: AppContext) {
        self.reviewRepository = repository
        self.context = context
    }

    // 현재 로그인한 사용자가 이 책에 남긴 리뷰를 찾는다.
    func myReview(for bookId: UUID) -> Review? {
        if let currentUserId = context.currentUserId {
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
            let savedReview = try await reviewRepository.saveReview(
                bookId: bookId,
                rating: rating,
                content: content,
                isPublic: isPublic
            )

            upsertReview(savedReview)
            context.operationErrorMessage = nil
            context.showToast("리뷰를 저장했어요.", style: .success)
            BMAnalytics.reviewSaved(
                hasRating: rating > 0,
                hasContent: !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                isPublic: isPublic
            )
            return true
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return false }

            context.operationErrorMessage = "리뷰 저장에 실패했습니다."
            context.showToast("리뷰 저장에 실패했어요.", style: .error)
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
            if let review = try await reviewRepository.fetchMyReview(bookId: bookId) {
                upsertReview(review)
            }
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return }

            context.showToast("리뷰를 불러오지 못했어요.", style: .error)
            DebugLogger.log("리뷰 조회 실패:", error)
        }
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
            publicBookReviews = try await reviewRepository.fetchPublicReviews(
                isbn: isbn,
                title: title,
                author: author
            )
        } catch {
            if context.handleUnauthorizedIfNeeded(error) { return }

            publicBookReviews = []
            publicReviewErrorMessage = "공개 리뷰를 불러오지 못했어요."
            DebugLogger.log("공개 리뷰 조회 실패:", error)
        }

        isPublicReviewLoading = false
    }
}
