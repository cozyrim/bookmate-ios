import Foundation

extension AppDependencies {
    static var usesUIFixtures: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
        #else
        false
        #endif
    }

    static func bootstrap() -> AppDependencies {
        #if DEBUG
        if usesUIFixtures {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            let library = UIFixtureLibrary()
            let social = UIFixtureSocial()
            let external = UIFixtureExternal()
            return AppDependencies(
                readingReminders: external, notifications: UIFixtureNotifications(),
                social: social, moderation: social, auth: UIFixtureAuth(), tokens: UIFixtureTokens(),
                pushTokens: external, dictionary: external, searchPreferences: external,
                books: library, words: library, quotes: library, memos: library, reviews: library,
                bestsellers: external, bookSearch: external, bookPages: external, bookMetadata: external,
                dictionaryExamples: external, recentSearches: external,
                readingSessions: FileReadingSessionRepository(environment: "ui-fixture"), shelfOrder: external
            )
        }
        #endif
        return AppDependencies()
    }
}
