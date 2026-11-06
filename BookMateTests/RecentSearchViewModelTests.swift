import XCTest
@testable import BookMate

@MainActor
final class RecentSearchViewModelTests: XCTestCase {
    func testAddingSearchUpdatesScreenAndInjectedRepository() async {
        let repository = MemoryRecentSearchRepository()
        let viewModel = BookMateViewModel(recentSearchRepository: repository)
        let ownerID = UUID()
        viewModel.setRecentSearchOwner(userId: ownerID)
        viewModel.searchMode = .book
        viewModel.recentSearches = ["독서", "여행"]

        viewModel.addRecentSearch(" 여행\n")

        XCTAssertEqual(viewModel.recentSearches, ["여행", "독서"])
        XCTAssertEqual(repository.saveCount, 1)
        XCTAssertEqual(repository.load(for: RecentSearchScope(ownerID: ownerID, mode: .book)), ["여행", "독서"])
    }

    func testDisabledAndBlankSearchesDoNotChangeOrSaveHistory() async {
        let repository = MemoryRecentSearchRepository()
        let viewModel = BookMateViewModel(recentSearchRepository: repository)
        viewModel.recentSearches = ["독서"]
        repository.isSavingEnabled = false
        viewModel.addRecentSearch("여행")
        repository.isSavingEnabled = true
        viewModel.addRecentSearch(" \n")
        XCTAssertEqual(viewModel.recentSearches, ["독서"])
        XCTAssertEqual(repository.saveCount, 0)
    }

    func testHistoryCanBeLoadedAndDeletedWhileSavingIsDisabled() async {
        let scope = RecentSearchScope(ownerID: nil, mode: .dictionary)
        let repository = MemoryRecentSearchRepository()
        repository.records[scope] = ["독서", "여행"]
        repository.isSavingEnabled = false
        let viewModel = BookMateViewModel(recentSearchRepository: repository)
        viewModel.loadRecentSearches()
        XCTAssertEqual(viewModel.recentSearches, ["독서", "여행"])
        viewModel.removeRecentSearch(" 독서 ")
        XCTAssertEqual(viewModel.recentSearches, ["여행"])
        XCTAssertEqual(repository.records[scope], ["여행"])
    }

    func testOwnerAndModeChangesLoadMatchingHistory() async {
        let ownerID = UUID()
        let repository = MemoryRecentSearchRepository()
        repository.records[RecentSearchScope(ownerID: ownerID, mode: .dictionary)] = ["사전 기록"]
        repository.records[RecentSearchScope(ownerID: ownerID, mode: .savedWords)] = ["저장 기록"]
        repository.records[RecentSearchScope(ownerID: nil, mode: .savedWords)] = ["게스트 기록"]
        let viewModel = BookMateViewModel(recentSearchRepository: repository)
        viewModel.setRecentSearchOwner(userId: ownerID)
        XCTAssertEqual(viewModel.recentSearches, ["사전 기록"])
        viewModel.searchMode = .savedWords
        viewModel.loadRecentSearches()
        XCTAssertEqual(viewModel.recentSearches, ["저장 기록"])
        viewModel.setRecentSearchOwner(userId: nil)
        XCTAssertEqual(viewModel.recentSearches, ["게스트 기록"])
    }
}

@MainActor
private final class MemoryRecentSearchRepository: RecentSearchRepository {
    var isSavingEnabled = true
    var records: [RecentSearchScope: [String]] = [:]
    private(set) var saveCount = 0

    func load(for scope: RecentSearchScope) -> [String] { records[scope] ?? [] }

    func save(_ searches: [String], for scope: RecentSearchScope) {
        records[scope] = searches
        saveCount += 1
    }
}
