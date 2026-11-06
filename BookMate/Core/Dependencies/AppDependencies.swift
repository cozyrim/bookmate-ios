import Foundation

@MainActor
struct AppDependencies {
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
