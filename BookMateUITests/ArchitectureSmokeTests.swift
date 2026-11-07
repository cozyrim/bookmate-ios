import XCTest

@MainActor
final class ArchitectureSmokeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testMainTabsRenderWithInjectedDataInBothAppearances() {
        for appearance in ["light", "dark"] {
            let app = launch(appearance: appearance)
            for (index, label) in ["홈", "책", "단어장", "서재", "프로필"].enumerated() {
                let button = tab(label, in: app)
                XCTAssertTrue(button.waitForExistence(timeout: 10), label)
                button.tap()
                assertDestination(label, in: app)
                capture("\(appearance)-tab-\(index)", app: app)
            }
            app.terminate()
        }
    }

    func testDictionarySearchShowsRepositoryResultAndSaveAction() {
        let app = launch()
        let input = app.textFields.firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        input.typeText("여행")
        XCTAssertEqual(input.value as? String, "여행")
        app.buttons["home.search.submit"].tap()
        let definition = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "여행의 뜻을 확인합니다.")).firstMatch
        XCTAssertTrue(definition.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["저장하기"].firstMatch.exists)
        capture("dictionary-result", app: app)
    }

    func testBestsellerUsesExistingRegistrationFlow() {
        let app = launch()
        app.buttons["책 추가"].tap()
        let item = app.buttons["bestsellers.item.123"]
        for _ in 0..<3 {
            if item.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(item.waitForExistence(timeout: 10))
        capture("realtime-bestsellers", app: app)
        item.tap()
        XCTAssertTrue(app.buttons["YES24에서 도서 정보 보기"].waitForExistence(timeout: 10))
        app.buttons["book.registration.save"].tap()
        let saved = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "베스트셀러 테스트 도서,")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 15))
    }

    func testBestsellerFailureKeepsManualRegistrationAvailable() {
        let app = launch(extraArguments: ["--bestseller-error"])
        app.buttons["책 추가"].tap()
        XCTAssertTrue(app.staticTexts["bestsellers.error"].waitForExistence(timeout: 10))
        let manual = app.buttons["직접 등록"].firstMatch
        if !manual.isHittable { app.swipeDown() }
        manual.tap()
        XCTAssertTrue(app.buttons["book.registration.manualSave"].waitForExistence(timeout: 10))
    }

    func testSearchBookRegistersWithoutManualOrCompletionScreen() {
        let app = launch()
        app.buttons["책 추가"].tap()
        let input = app.textFields["책 제목 또는 저자를 입력하세요."]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("새로운책")
        let result = app.staticTexts["새로운책"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()
        let save = app.buttons["book.registration.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        capture("quick-registration-detail", app: app)
        save.tap()
        let saved = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "새로운책,")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["새 책 등록"].exists)
        capture("registered-book-on-shelf", app: app)
    }

    func testLeavingSlowRegistrationDoesNotDismissTheSearchScreen() {
        let app = launch(extraArguments: ["--slow-book-registration"])
        app.buttons["책 추가"].tap()
        let input = app.textFields["책 제목 또는 저자를 입력하세요."]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("느린 책")
        let result = app.staticTexts["느린 책"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()
        let save = app.buttons["book.registration.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        save.tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["책을 등록했어요."].waitForExistence(timeout: 15))
        XCTAssertTrue(input.exists, "A completed background save must not pop the search screen")
    }

    func testManualRegistrationRequiresTitleAndAuthorAndReturnsToShelf() {
        let app = launch()
        app.buttons["책 추가"].tap()
        let manual = app.buttons["직접 등록"].firstMatch
        XCTAssertTrue(manual.waitForExistence(timeout: 10))
        manual.tap()
        let save = app.buttons["book.registration.manualSave"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertFalse(save.isEnabled)
        XCTAssertFalse(app.buttons["홈"].exists, "Registration must not show the compact tab bar")
        let title = app.textFields["제목을 입력하세요"]
        title.tap()
        title.typeText("직접 쓴 책")
        let author = app.textFields["저자를 입력하세요"]
        author.tap()
        author.typeText("새 저자")
        app.swipeUp()
        XCTAssertTrue(save.isEnabled)
        capture("manual-registration-form", app: app)
        save.tap()
        let saved = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "직접 쓴 책,")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 15))
    }

    func testLibraryDetailKeepsWordQuoteAndDiaryTabs() {
        let app = launch()
        tab("책", in: app).tap()
        let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "싯타르타,")).firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 10))
        book.tap()
        for label in ["단어", "문장", "다이어리"] {
            let button = app.staticTexts[label].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10), label)
            button.tap()
        }
        XCTAssertTrue(app.staticTexts["독서 기록"].waitForExistence(timeout: 5))
        capture("book-detail-diary", app: app)
    }

    func testHomeReadingShelfLimitsBooksAndOpensSelectedCover() {
        let app = launch(extraArguments: ["--home-reading-carousel"])
        let shelf = app.scrollViews["home.reading.shelf"]
        let position = app.staticTexts["home.reading.position"]
        let detail = app.buttons["home.reading.detail"]

        XCTAssertTrue(shelf.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Bookmate 오늘 만난 문장"].exists)
        XCTAssertFalse(app.staticTexts["읽다가 만난 단어들"].exists)
        XCTAssertEqual(position.label, "5권 중 1번째")
        XCTAssertTrue(detail.label.contains("싯타르타"))
        capture("home-reading-initial", app: app)

        let start = shelf.coordinate(withNormalizedOffset: CGVector(dx: 0.69, dy: 0.49))
        let end = shelf.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.49))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.12)
        let second = NSPredicate(format: "label == %@", "5권 중 2번째")
        expectation(for: second, evaluatedWith: position)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(detail.label.contains("참을 수 없는 존재의 가벼움"))
        capture("home-reading-swiped", app: app)

        app.buttons["다음 책"].tap()
        XCTAssertEqual(position.label, "5권 중 3번째")
        app.buttons["home.reading.cover.33333333-3333-3333-3333-333333333333"].tap()
        XCTAssertTrue(app.staticTexts["다이어리"].waitForExistence(timeout: 10))
    }

    func testImmersiveRoomCompositionAndCompactHome() {
        let app = launch(extraArguments: ["--room-books", "--recent-search-fixture"])
        let progress = app.progressIndicators["home.reading.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        XCTAssertLessThan(progress.frame.maxY, tab("홈", in: app).frame.minY)
        capture("compact-home-with-recents", app: app)
        tab("서재", in: app).tap()
        let lamp = app.buttons["miniRoom.wood3D.lamp"]
        if !lamp.exists {
            app.buttons["배경"].tap()
            app.buttons["miniRoom.theme.wood3D"].tap()
            app.buttons["배경 적용하기"].tap()
        }
        XCTAssertTrue(lamp.waitForExistence(timeout: 10))
        if app.frame.width < 600 {
            XCTAssertLessThan(lamp.frame.maxY, tab("서재", in: app).frame.minY,
                              "Room controls must remain above the compact tab bar")
        }
        capture("immersive-lamp-on", app: app)
        lamp.tap()
        XCTAssertEqual(lamp.value as? String, "꺼짐")
        capture("immersive-lamp-off", app: app)
        lamp.tap()
        app.buttons["miniRoom.wood3D.books"].tap()
        capture("immersive-room-wide", app: app)
    }

    func testWoodRoomOpensExistingBookAndGuestbookAndSwitchesLight() {
        let app = launch(extraArguments: ["--room-books"])
        tab("서재", in: app).tap()
        let lamp = app.buttons["miniRoom.wood3D.lamp"]
        if !lamp.exists {
            app.buttons["배경"].tap()
            let theme = app.buttons["miniRoom.theme.wood3D"]
            XCTAssertTrue(theme.waitForExistence(timeout: 10))
            theme.tap()
            app.buttons["배경 적용하기"].tap()
        }

        XCTAssertTrue(lamp.waitForExistence(timeout: 15))
        let canvas = app.descendants(matching: .any)["miniRoom.wood3D.canvas"].firstMatch
        XCTAssertTrue(canvas.exists)
        capture("real-book-shelf", app: app)
        app.buttons["다음 책장"].tap()
        XCTAssertFalse(app.buttons["다음 책장"].isEnabled)
        capture("real-book-second-page", app: app)
        app.buttons["이전 책장"].tap()
        app.buttons["miniRoom.wood3D.books"].tap()
        XCTAssertEqual(lamp.value as? String, "켜짐")
        capture("wood-room-lamp-on", app: app)
        // The room renders edge-to-edge; target the visible objects in screen coordinates.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.44, dy: 0.525)).tap()
        XCTAssertEqual(lamp.value as? String, "꺼짐")
        capture("wood-room-lamp-off", app: app)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.563)).tap()
        XCTAssertTrue(app.staticTexts["좋은 책장을 구경했어요."].waitForExistence(timeout: 10))
        let guestbookTitle = app.staticTexts["독서가님의 방명록"]
        let dismissal = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.88))
        guestbookTitle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.08, thenDragTo: dismissal)
        let visible = NSPredicate(format: "hittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: lamp)], timeout: 10), .completed)
        app.buttons["miniRoom.wood3D.books"].tap()
        let orbitStart = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.40))
        let orbitEnd = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.67, dy: 0.40))
        orbitStart.press(forDuration: 0.1, thenDragTo: orbitEnd)
        capture("immersive-after-orbit", app: app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.40, dy: 0.32)).tap()
        XCTAssertTrue(app.staticTexts["다이어리"].waitForExistence(timeout: 10))
    }

    func testTabBarReturnsWhenScrollingStops() {
        let app = launch(extraArguments: ["--home-reading-carousel"])
        let scroll = app.scrollViews.firstMatch
        scroll.swipeUp(velocity: .fast)
        let home = tab("홈", in: app)
        let visible = NSPredicate(format: "hittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: home)], timeout: 5), .completed)
        capture("tab-bar-after-scroll", app: app)
        scroll.swipeDown(velocity: .fast)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: home)], timeout: 5), .completed)
        tab("서재", in: app).tap()
        assertDestination("서재", in: app)
    }

    private func launch(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-appColorMode", appearance, "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"] + extraArguments
        app.launch()
        XCTAssertTrue(tab("홈", in: app).waitForExistence(timeout: 15))
        return app
    }

    private func tab(_ label: String, in app: XCUIApplication) -> XCUIElement {
        let tabButton = app.tabBars.buttons[label].firstMatch
        return tabButton.exists ? tabButton : app.buttons[label].firstMatch
    }

    private func assertDestination(_ label: String, in app: XCUIApplication) {
        let expected: XCUIElement
        switch label {
        case "홈":
            expected = app.staticTexts["최근 저장 단어"].firstMatch
        case "책":
            expected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "싯타르타,")).firstMatch
        case "단어장":
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "전체 책")).firstMatch.waitForExistence(timeout: 10))
            expected = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "찰나")).firstMatch
        case "서재":
            expected = app.staticTexts.matching(NSPredicate(format: "label IN %@", ["독서가님의 책장", "독서가님의 서재"])).firstMatch
        case "프로필":
            expected = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "프로필 수정")).firstMatch
        default:
            XCTFail("Missing destination assertion: \(label)")
            return
        }
        XCTAssertTrue(expected.waitForExistence(timeout: 10), "Destination: \(label)")
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
