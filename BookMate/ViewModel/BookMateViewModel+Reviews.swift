import Foundation

extension BookMateViewModel {
    func myReview(for bookId: UUID) -> Review? { reviewFeature.myReview(for: bookId) }
    func publicReviews(for bookId: UUID) -> [Review] { reviewFeature.publicReviews(for: bookId) }
    func saveReview(bookId: UUID, rating: Int, content: String, isPublic: Bool) async -> Bool {
        await reviewFeature.saveReview(bookId: bookId, rating: rating, content: content, isPublic: isPublic)
    }
    func upsertReview(_ review: Review) { reviewFeature.upsertReview(review) }
    func loadMyReview(bookId: UUID) async { await reviewFeature.loadMyReview(bookId: bookId) }
    func loadPublicReviews(isbn: String, title: String, author: String) async {
        await reviewFeature.loadPublicReviews(isbn: isbn, title: title, author: author)
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
        let normalizedRating = rating.flatMap { $0 > 0 ? $0 : nil }
        let progress = readingStatus == .completed ? 1.0 : book.progress
        let currentPage = readingStatus == .completed
            ? book.totalPages ?? book.currentPage
            : book.currentPage

        let updatedBook = Book(
            id: book.id,
            title: book.title,
            author: book.author,
            imageName: book.imageName,
            category: book.category,
            progress: progress,
            totalPages: book.totalPages,
            currentPage: currentPage,
            rating: normalizedRating,
            review: review,
            readingStatus: readingStatus,
            startDate: startDate,
            endDate: endDate
        )
        return await updateBook(updatedBook, successMessage: "리뷰를 저장했어요.")
    }

}
