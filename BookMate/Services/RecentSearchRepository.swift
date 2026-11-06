protocol RecentSearchRepository {
    var isSavingEnabled: Bool { get }

    func load(for scope: RecentSearchScope) -> [String]
    func save(_ searches: [String], for scope: RecentSearchScope)
}
