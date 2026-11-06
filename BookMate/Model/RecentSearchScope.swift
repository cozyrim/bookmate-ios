import Foundation

struct RecentSearchScope: Hashable {
    enum Mode: String, CaseIterable {
        case dictionary
        case book
        case savedWords
    }

    let ownerID: UUID?
    let mode: Mode

    var storageKey: String {
        let ownerKey = ownerID?.uuidString ?? "guest"
        return "recentSearches.\(mode.rawValue).\(ownerKey)"
    }
}
