import XCTest
@testable import BookMate

@MainActor
final class RecentSearchHistoryTests: XCTestCase {
    func testNewSearchIsPlacedFirst() async {
        XCTAssertEqual(
            RecentSearchHistory.adding("문장", to: ["독서", "여행"]),
            ["문장", "독서", "여행"]
        )
    }

    func testRepeatedSearchMovesToFrontWithoutDuplicates() async {
        XCTAssertEqual(
            RecentSearchHistory.adding("여행", to: ["독서", "여행", "문장", "여행"]),
            ["여행", "독서", "문장"]
        )
    }

    func testSearchTrimsSurroundingWhitespace() async {
        XCTAssertEqual(
            RecentSearchHistory.adding(" \n여행\t", to: ["독서", "여행"]),
            ["여행", "독서"]
        )
    }

    func testBlankSearchDoesNotProduceAnUpdate() async {
        for word in ["", " ", "\n\t"] {
            XCTAssertNil(RecentSearchHistory.adding(word, to: ["독서"]))
        }
    }

    func testNewSearchKeepsOnlyTenMostRecentTerms() async {
        let previous = (1...10).map { "검색어\($0)" }
        XCTAssertEqual(
            RecentSearchHistory.adding("새 검색어", to: previous),
            ["새 검색어"] + (1...9).map { "검색어\($0)" }
        )
    }

    func testDuplicateMatchingRemainsCaseSensitive() async {
        XCTAssertEqual(
            RecentSearchHistory.adding("Swift", to: ["swift", "Swift"]),
            ["Swift", "swift"]
        )
    }

    func testRemovingSearchTrimsInputAndRemovesAllMatches() async {
        XCTAssertEqual(
            RecentSearchHistory.removing(" 여행\n", from: ["여행", "독서", "여행"]),
            ["독서"]
        )
    }

    func testRemovingMissingSearchPreservesOrderAndCount() async {
        let previous = (1...12).map { "검색어\($0)" }
        XCTAssertEqual(RecentSearchHistory.removing("없음", from: previous), previous)
    }

    func testUpdatingHistoryDoesNotChangeTheInputArray() async {
        let original = ["독서", "여행"]
        _ = RecentSearchHistory.adding("문장", to: original)
        _ = RecentSearchHistory.removing("독서", from: original)
        XCTAssertEqual(original, ["독서", "여행"])
    }
}

@MainActor
final class RecentSearchRepositoryTests: XCTestCase {
    private func withStore(
        _ body: (UserDefaultsRecentSearchRepository, UserDefaults) throws -> Void
    ) throws {
        let suiteName = "BookMateTests.RecentSearches.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(UserDefaultsRecentSearchRepository(defaults: defaults), defaults)
    }

    func testStorageKeysMatchTheExistingFormat() async throws {
        let ownerID = try XCTUnwrap(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        for mode in RecentSearchScope.Mode.allCases {
            XCTAssertEqual(
                RecentSearchScope(ownerID: ownerID, mode: mode).storageKey,
                "recentSearches.\(mode.rawValue).11111111-2222-3333-4444-555555555555"
            )
            XCTAssertEqual(
                RecentSearchScope(ownerID: nil, mode: mode).storageKey,
                "recentSearches.\(mode.rawValue).guest"
            )
        }
    }

    func testLoadsExistingJSONDataWithoutMigration() async throws {
        try withStore { repository, defaults in
            let scope = RecentSearchScope(ownerID: nil, mode: .dictionary)
            defaults.set(Data("[\"독서\",\"여행\"]".utf8), forKey: "recentSearches.dictionary.guest")
            XCTAssertEqual(repository.load(for: scope), ["독서", "여행"])
        }
    }

    func testSavedDataCanBeReadByTheExistingDecoder() async throws {
        try withStore { repository, defaults in
            let scope = RecentSearchScope(ownerID: nil, mode: .book)
            repository.save(["독서", "여행"], for: scope)

            let data = try XCTUnwrap(defaults.data(forKey: "recentSearches.book.guest"))
            XCTAssertEqual(try JSONDecoder().decode([String].self, from: data), ["독서", "여행"])
        }
    }

    func testRecordsStaySeparateForEachOwnerAndMode() async throws {
        try withStore { repository, _ in
            let ownerA = UUID()
            let ownerB = UUID()
            let scopes = [nil, ownerA, ownerB].flatMap { ownerID in
                RecentSearchScope.Mode.allCases.map { RecentSearchScope(ownerID: ownerID, mode: $0) }
            }

            for (index, scope) in scopes.enumerated() {
                repository.save(["기록\(index)"], for: scope)
            }
            for (index, scope) in scopes.enumerated() {
                XCTAssertEqual(repository.load(for: scope), ["기록\(index)"])
            }
        }
    }

    func testMissingAndInvalidDataLoadAsEmptyHistory() async throws {
        try withStore { repository, defaults in
            let scope = RecentSearchScope(ownerID: nil, mode: .dictionary)
            XCTAssertEqual(repository.load(for: scope), [])

            for invalid in ["not JSON", "{}", "[1,2]"] {
                defaults.set(Data(invalid.utf8), forKey: scope.storageKey)
                XCTAssertEqual(repository.load(for: scope), [])
            }
        }
    }

    func testLoadingHistoryDoesNotTruncateExistingRecords() async throws {
        try withStore { repository, _ in
            let scope = RecentSearchScope(ownerID: nil, mode: .savedWords)
            let previous = (1...12).map { "검색어\($0)" }
            repository.save(previous, for: scope)
            XCTAssertEqual(repository.load(for: scope), previous)
        }
    }

    func testSavingIsEnabledByDefaultAndReadsUpdatedPreference() async throws {
        try withStore { repository, defaults in
            XCTAssertTrue(repository.isSavingEnabled)
            defaults.set(false, forKey: "savesRecentSearches")
            XCTAssertFalse(repository.isSavingEnabled)
            defaults.set(true, forKey: "savesRecentSearches")
            XCTAssertTrue(repository.isSavingEnabled)
        }
    }

    func testDisablingNewSearchesDoesNotHideStoredHistory() async throws {
        try withStore { repository, defaults in
            let scope = RecentSearchScope(ownerID: nil, mode: .dictionary)
            repository.save(["독서"], for: scope)
            defaults.set(false, forKey: "savesRecentSearches")

            XCTAssertFalse(repository.isSavingEnabled)
            XCTAssertEqual(repository.load(for: scope), ["독서"])
            repository.save([], for: scope)
            XCTAssertEqual(repository.load(for: scope), [])
        }
    }

    func testInjectedStoresDoNotShareHistory() async throws {
        try withStore { first, _ in
            try withStore { second, _ in
                let scope = RecentSearchScope(ownerID: nil, mode: .dictionary)
                first.save(["독서"], for: scope)
                XCTAssertEqual(second.load(for: scope), [])
            }
        }
    }
}
