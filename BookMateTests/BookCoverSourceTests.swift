import XCTest
@testable import BookMate

final class BookCoverSourceTests: XCTestCase {
    func testKakaoThumbnailUsesHTTPSOriginalAndPreservesItsQuery() {
        let url = URL(string: "https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.daumcdn.net%2Flbook%2Fimage%2F615226%3Ftimestamp%3D20250314113803")!
        XCTAssertEqual(BookCoverSource.preferredURL(for: url).absoluteString,
                       "https://t1.daumcdn.net/lbook/image/615226?timestamp=20250314113803")
    }

    func testUnrecognizedSourcesAreNeverRewritten() {
        for string in [
            "https://example.com/cover.jpg?fname=https://t1.daumcdn.net/lbook/image/1",
            "https://search1.kakaocdn.net/thumb/R120x174/?fname=https://example.com/private",
            "https://search1.kakaocdn.net/thumb/R120x174/?fname=file:///etc/passwd",
            "https://search1.kakaocdn.net/thumb/R120x174/?fname=https://t1.daumcdn.net.evil.com/lbook/image/1",
            "https://search1.kakaocdn.net/thumb/R120x174/?fname=https://t1.daumcdn.net:8443/lbook/image/1",
            "https://search1.kakaocdn.net/thumb/R120x174/",
            "https://t1.daumcdn.net/lbook/image/615226"
        ] {
            let url = URL(string: string)!
            XCTAssertEqual(BookCoverSource.preferredURL(for: url), url)
        }
    }
}
