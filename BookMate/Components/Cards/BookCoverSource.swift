import Foundation

/// Presentation-only URL selection. The saved book and its thumbnail URL stay unchanged.
enum BookCoverSource {
    static func preferredURL(for thumbnail: URL) -> URL {
        guard let host = thumbnail.host?.lowercased(),
              ["search1.kakaocdn.net", "search2.kakaocdn.net", "search3.kakaocdn.net", "search4.kakaocdn.net"].contains(host),
              thumbnail.path.hasPrefix("/thumb/"),
              let source = URLComponents(url: thumbnail, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "fname" })?.value,
              var original = URLComponents(string: source),
              ["http", "https"].contains(original.scheme?.lowercased() ?? ""),
              original.host?.lowercased() == "t1.daumcdn.net",
              original.path.hasPrefix("/lbook/image/"),
              original.user == nil, original.password == nil, original.port == nil else { return thumbnail }
        original.scheme = "https"
        return original.url ?? thumbnail
    }
}
