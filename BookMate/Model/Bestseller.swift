import Foundation

struct BestsellerFeed: Decodable {
    let source: String
    let fetchedAt: String
    let items: [Bestseller]
}

struct Bestseller: Decodable, Identifiable {
    let rank: Int
    let id: String
    let title: String
    let author: String
    let publisher: String
    let isbn: String
    let cover: String
    let productUrl: String
    let totalPages: Int?
    let introduction: String?

    var sourceURL: URL? {
        guard let url = URL(string: productUrl), url.scheme == "https", url.host == "www.yes24.com" else { return nil }
        return url
    }

    var registrationDraft: BookRegistrationDraft {
        BookRegistrationDraft(id: "yes24-" + id, title: title, author: author,
                              publisher: publisher, contents: introduction ?? "", imageName: cover.isEmpty ? "책기본이미지" : cover,
                              isbn: isbn, totalPages: totalPages)
    }
}
