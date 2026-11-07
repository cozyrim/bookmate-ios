import XCTest
@testable import BookMate

@MainActor
final class BestsellerTests: XCTestCase {
    func testLoadsProviderRanksAndPreservesRegistrationMetadata() async {
        let repo = StubBestsellers()
        let model = BestsellerViewModel(repository: repo)
        await model.load()
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorMessage)
        let book = model.feed!.items[0]
        XCTAssertEqual(book.rank, 3)
        XCTAssertEqual(book.registrationDraft.totalPages, 248)
        XCTAssertEqual(book.registrationDraft.isbn, "9780000000001")
        XCTAssertEqual(book.registrationDraft.title, "도서")
        XCTAssertNotNil(book.sourceURL)
        XCTAssertNotEqual(model.updatedTimeText, "최근")
    }

    func testFailedRefreshClearsStaleFeedAndRetryRecovers() async {
        let repo = StubBestsellers()
        let model = BestsellerViewModel(repository: repo)
        await model.load()
        repo.shouldFail = true
        await model.load()
        XCTAssertNil(model.feed)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
        repo.shouldFail = false
        await model.load()
        XCTAssertNotNil(model.feed)
        XCTAssertNil(model.errorMessage)
    }

    func testCancellationDoesNotPublishFailure() async {
        let repo = StubBestsellers()
        let model = BestsellerViewModel(repository: repo)
        let task = Task { await model.load() }
        task.cancel()
        await task.value
        XCTAssertNil(model.feed)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }
}

@MainActor
private final class StubBestsellers: BestsellerRepository {
    var shouldFail = false
    func fetchRealtime() async throws -> BestsellerFeed {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return BestsellerFeed(source: "YES24", fetchedAt: "2026-11-08T00:00:00Z", items: [
            Bestseller(rank: 3, id: "123", title: "도서", author: "저자", publisher: "출판사",
                       isbn: "9780000000001", cover: "", productUrl: "https://www.yes24.com/product/goods/123", totalPages: 248)
        ])
    }
}
