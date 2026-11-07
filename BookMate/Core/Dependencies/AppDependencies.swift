import Foundation

@MainActor
struct AppDependencies {
    let readingReminders: any ReadingReminderScheduling
    let notifications: any NotificationRepository
    let social: any SocialRepository
    let moderation: any ModerationRepository
    let auth: any AuthRepository
    let tokens: any AuthTokenStore
    let kakaoLogin: any KakaoLoginProviding
    let appleAuthorization: any AppleAuthorizationDecoding
    let pushTokens: any PushTokenManaging
    let dictionary: any DictionaryRepository
    let searchPreferences: any SearchPreferencesRepository
    let books: any BookRepository
    let words: any WordRepository
    let quotes: any QuoteRepository
    let memos: any ReadingMemoRepository
    let reviews: any ReviewRepository
    let bestsellers: any BestsellerRepository
    let bookSearch: any BookSearchRepository
    let bookPages: any BookPageRepository
    let bookMetadata: any BookMetadataRepository
    let dictionaryExamples: any DictionaryExampleRepository
    let recentSearches: any RecentSearchRepository
    let shelfOrder: any ShelfOrderRepository

    init(
        readingReminders: (any ReadingReminderScheduling)? = nil,
        notifications: (any NotificationRepository)? = nil,
        social: (any SocialRepository)? = nil,
        moderation: (any ModerationRepository)? = nil,
        auth: (any AuthRepository)? = nil,
        tokens: (any AuthTokenStore)? = nil,
        kakaoLogin: (any KakaoLoginProviding)? = nil,
        appleAuthorization: (any AppleAuthorizationDecoding)? = nil,
        pushTokens: (any PushTokenManaging)? = nil,
        dictionary: (any DictionaryRepository)? = nil,
        searchPreferences: (any SearchPreferencesRepository)? = nil,
        books: (any BookRepository)? = nil,
        words: (any WordRepository)? = nil,
        quotes: (any QuoteRepository)? = nil,
        memos: (any ReadingMemoRepository)? = nil,
        reviews: (any ReviewRepository)? = nil,
        bestsellers: (any BestsellerRepository)? = nil,
        bookSearch: (any BookSearchRepository)? = nil,
        bookPages: (any BookPageRepository)? = nil,
        bookMetadata: (any BookMetadataRepository)? = nil,
        dictionaryExamples: (any DictionaryExampleRepository)? = nil,
        recentSearches: (any RecentSearchRepository)? = nil,
        shelfOrder: (any ShelfOrderRepository)? = nil
    ) {
        self.readingReminders = readingReminders ?? ReadingNotificationService.shared
        self.notifications = notifications ?? NotificationAPIService()
        self.social = social ?? SocialAPIService()
        self.moderation = moderation ?? ModerationAPIService()
        self.auth = auth ?? AuthAPIService()
        self.tokens = tokens ?? KeychainTokenStore()
        self.kakaoLogin = kakaoLogin ?? KakaoLoginService()
        self.appleAuthorization = appleAuthorization ?? AppleLoginService()
        self.pushTokens = pushTokens ?? PushNotificationService.shared
        self.dictionary = dictionary ?? StandardDictionaryRepository()
        self.searchPreferences = searchPreferences ?? UserDefaultsSearchPreferencesRepository()
        self.books = books ?? BookAPIService()
        self.words = words ?? WordAPIService()
        self.quotes = quotes ?? QuoteAPIService()
        self.memos = memos ?? ReadingMemoAPIService()
        self.reviews = reviews ?? ReviewAPIService()
        self.bestsellers = bestsellers ?? BestsellerAPIService()
        self.bookSearch = bookSearch ?? KakaoBookSearchService()
        self.bookPages = bookPages ?? BookPageLookupService()
        self.bookMetadata = bookMetadata ?? AladinBookLookupService()
        self.dictionaryExamples = dictionaryExamples ?? DictionaryExampleLookupService()
        self.recentSearches = recentSearches ?? UserDefaultsRecentSearchRepository()
        self.shelfOrder = shelfOrder ?? UserDefaultsShelfOrderRepository()
    }
}
