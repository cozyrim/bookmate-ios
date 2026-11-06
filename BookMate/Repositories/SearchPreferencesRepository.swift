import Foundation

protocol SearchPreferencesRepository {
    var suggestsSimilarWordsOnFailure: Bool { get }
}

struct UserDefaultsSearchPreferencesRepository: SearchPreferencesRepository {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    var suggestsSimilarWordsOnFailure: Bool {
        defaults.object(forKey: "suggestsSimilarWordsOnFailure") as? Bool ?? true
    }
}
