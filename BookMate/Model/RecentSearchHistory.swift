import Foundation

enum RecentSearchHistory {
    static func adding(_ word: String, to searches: [String]) -> [String]? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var updated = searches.filter { $0 != trimmed }
        updated.insert(trimmed, at: 0)
        return Array(updated.prefix(10))
    }

    static func removing(_ word: String, from searches: [String]) -> [String] {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        return searches.filter { $0 != trimmed }
    }
}
