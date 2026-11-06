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
        app.scrollViews.firstMatch.buttons["검색"].firstMatch.tap()
        let definition = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "여행의 뜻을 확인합니다.")).firstMatch
        XCTAssertTrue(definition.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["저장하기"].firstMatch.exists)
        capture("dictionary-result", app: app)
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
        capture("book-detail-diary", app: app)
    }

    private func launch(appearance: String = "light") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-appColorMode", appearance, "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
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
            expected = app.staticTexts["독서가님의 책장"].firstMatch
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
