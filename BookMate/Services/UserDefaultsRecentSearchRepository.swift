import Foundation

struct UserDefaultsRecentSearchRepository: RecentSearchRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isSavingEnabled: Bool {
        defaults.object(forKey: "savesRecentSearches") as? Bool ?? true
    }

    func load(for scope: RecentSearchScope) -> [String] {
        guard let data = defaults.data(forKey: scope.storageKey),
              let searches = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return searches
    }

    func save(_ searches: [String], for scope: RecentSearchScope) {
        guard let data = try? JSONEncoder().encode(searches) else { return }
        defaults.set(data, forKey: scope.storageKey)
    }
}
