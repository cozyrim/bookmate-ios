import Foundation

@MainActor
struct AppDependencies {
    let dictionary: any DictionaryRepository
    let searchPreferences: any SearchPreferencesRepository
    let books: any BookRepository
    let words: any WordRepository
    let quotes: any QuoteRepository
    let memos: any ReadingMemoRepository
    let reviews: any ReviewRepository
    let bookSearch: any BookSearchRepository
    let bookPages: any BookPageRepository
    let bookMetadata: any BookMetadataRepository
    let dictionaryExamples: any DictionaryExampleRepository
    let recentSearches: any RecentSearchRepository
    let shelfOrder: any ShelfOrderRepository

    init(
        dictionary: (any DictionaryRepository)? = nil,
        searchPreferences: (any SearchPreferencesRepository)? = nil,
        books: (any BookRepository)? = nil,
        words: (any WordRepository)? = nil,
        quotes: (any QuoteRepository)? = nil,
        memos: (any ReadingMemoRepository)? = nil,
        reviews: (any ReviewRepository)? = nil,
        bookSearch: (any BookSearchRepository)? = nil,
        bookPages: (any BookPageRepository)? = nil,
        bookMetadata: (any BookMetadataRepository)? = nil,
        dictionaryExamples: (any DictionaryExampleRepository)? = nil,
        recentSearches: (any RecentSearchRepository)? = nil,
        shelfOrder: (any ShelfOrderRepository)? = nil
    ) {
        self.dictionary = dictionary ?? StandardDictionaryRepository()
        self.searchPreferences = searchPreferences ?? UserDefaultsSearchPreferencesRepository()
        self.books = books ?? BookAPIService()
        self.words = words ?? WordAPIService()
        self.quotes = quotes ?? QuoteAPIService()
        self.memos = memos ?? ReadingMemoAPIService()
        self.reviews = reviews ?? ReviewAPIService()
        self.bookSearch = bookSearch ?? KakaoBookSearchService()
        self.bookPages = bookPages ?? BookPageLookupService()
        self.bookMetadata = bookMetadata ?? AladinBookLookupService()
        self.dictionaryExamples = dictionaryExamples ?? DictionaryExampleLookupService()
        self.recentSearches = recentSearches ?? UserDefaultsRecentSearchRepository()
        self.shelfOrder = shelfOrder ?? UserDefaultsShelfOrderRepository()
    }
}
