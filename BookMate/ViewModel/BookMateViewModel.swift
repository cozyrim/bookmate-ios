//
//  BookMateViewModel.swift
//  BookMate
//
//  Created by 한채림 on 5/17/26.
//
// Published 상태, 서비스 의존성, 공통 함수를 관리한다.

import SwiftUI
import Combine

// UI 상태를 바꾸는 ViewModel이므로 MainActor에서 실행되도록 제한한다.
@MainActor
final class BookMateViewModel: ObservableObject {
    // MARK: - Types

    typealias SearchMode = RecentSearchScope.Mode

    typealias ArchiveSortOrder = WordViewModel.ArchiveSortOrder

    // MARK: - Archive State

    // nil이면 전체 카테고리를 의미한다.
    var archiveSelectedCategory: String? {
        get { wordFeature.archiveSelectedCategory }
        set { wordFeature.archiveSelectedCategory = newValue }
    }

    // nil이면 전체 책을 의미한다.
    var archiveSelectedBookId: UUID? {
        get { wordFeature.archiveSelectedBookId }
        set { wordFeature.archiveSelectedBookId = newValue }
    }

    // 단어 아카이브 정렬 기준이다.
    var archiveSortOrder: ArchiveSortOrder {
        get { wordFeature.archiveSortOrder }
        set { wordFeature.archiveSortOrder = newValue }
    }

    // MARK: - Book State

    // 서버에서 불러온 내 책 목록이다.
    var books: [Book] {
        get { libraryFeature.books }
        set { libraryFeature.books = newValue }
    }

    // 책장 화면 렌더링에 사용하는 책별 진행 상태 목록이다.
    var shelfBooks: [ShelfBook] {
        get { libraryFeature.shelfBooks }
        set { libraryFeature.shelfBooks = newValue }
    }

    // 새 책 등록 시 카카오 책 검색 결과를 담는다.
    var bookSearchResults: [KakaoBook] {
        get { searchFeature.bookSearchResults }
        set { searchFeature.bookSearchResults = newValue }
    }

    // 책 검색 요청 중인지 나타낸다.
    var isBookSearchLoading: Bool {
        get { searchFeature.isBookSearchLoading }
        set { searchFeature.isBookSearchLoading = newValue }
    }

    // 책 검색 실패 메시지다.
    var bookSearchErrorMessage: String? {
        get { searchFeature.bookSearchErrorMessage }
        set { searchFeature.bookSearchErrorMessage = newValue }
    }

    // 책 목록 조회 실패 메시지다.
    var bookLoadErrorMessage: String? {
        get { libraryFeature.bookLoadErrorMessage }
        set { libraryFeature.bookLoadErrorMessage = newValue }
    }

    // 다른 탭에서 책장 안의 특정 책으로 이동해 달라고 요청하는 1회성 상태다.
    var pendingShelfBookPresentationID: UUID? {
        get { libraryFeature.pendingShelfBookPresentationID }
        set { libraryFeature.pendingShelfBookPresentationID = newValue }
    }

    // MARK: - Word & Search State

    // 사용자가 책에 저장한 단어 목록이다.
    var savedWords: [Word] {
        get { wordFeature.savedWords }
        set { wordFeature.savedWords = newValue }
    }

    // 검색창 TextField에 입력 중인 문자열이다.
    var searchText: String {
        get { searchFeature.searchText }
        set { searchFeature.searchText = newValue }
    }

    // 현재 검색 모드다. 사전 API 검색과 저장 단어 검색을 구분한다.
    var searchMode: SearchMode {
        get { searchFeature.searchMode }
        set { searchFeature.searchMode = newValue }
    }

    // 사전 API에서 최종 선택된 검색 결과다.
    var dictionarySearchResult: DictionaryEntry? {
        get { searchFeature.dictionarySearchResult }
        set { searchFeature.dictionarySearchResult = newValue }
    }

    // 단어 저장 시트 표시 상태다.
    var isWordSaveSheetPresented: Bool {
        get { wordFeature.isWordSaveSheetPresented }
        set { wordFeature.isWordSaveSheetPresented = newValue }
    }

    // 단어 저장 중 책 등록을 시작했을 때, 등록 완료 후 저장 시트로 돌아갈지 나타낸다.
    var shouldResumeWordSaveAfterBookRegistration: Bool {
        get { wordFeature.shouldResumeWordSaveAfterBookRegistration }
        set { wordFeature.shouldResumeWordSaveAfterBookRegistration = newValue }
    }

    // 책 등록 완료 후 홈 화면 위에 단어 저장 시트를 다시 띄울지 나타낸다.
    var isWordSaveResumeSheetPresented: Bool {
        get { wordFeature.isWordSaveResumeSheetPresented }
        set { wordFeature.isWordSaveResumeSheetPresented = newValue }
    }

    // 책 등록 후 단어 저장 시트에서 자동 선택할 책 ID다.
    var wordSaveBookIdToSelectAfterRegistration: UUID? {
        get { wordFeature.wordSaveBookIdToSelectAfterRegistration }
        set { wordFeature.wordSaveBookIdToSelectAfterRegistration = newValue }
    }

    // 저장 단어 검색 모드에서 보여줄 검색 결과다.
    var savedWordSearchResults: [Word] {
        get { searchFeature.savedWordSearchResults }
        set { searchFeature.savedWordSearchResults = newValue }
    }

    // 저장 책 검색 모드에서 보여줄 검색 결과다.
    var savedBookSearchResults: [Book] {
        get { searchFeature.savedBookSearchResults }
        set { searchFeature.savedBookSearchResults = newValue }
    }

    // 사전 API 검색 요청 중인지 나타낸다.
    var isLoading: Bool {
        get { searchFeature.isLoading }
        set { searchFeature.isLoading = newValue }
    }

    // 사전 검색 실패 시 제안할 후보 단어 목록이다.
    var dictionarySuggestions: [DictionaryEntry] {
        get { searchFeature.dictionarySuggestions }
        set { searchFeature.dictionarySuggestions = newValue }
    }

    // 최근 검색어 목록이다.
    var recentSearches: [String] {
        get { searchFeature.recentSearches }
        set { searchFeature.recentSearches = newValue }
    }

    // 사전 검색, 저장 단어 검색에서 보여줄 오류 메시지다.
    var searchErrorMessage: String? {
        get { searchFeature.searchErrorMessage }
        set { searchFeature.searchErrorMessage = newValue }
    }

    // 저장 단어 조회 실패 메시지다.
    var wordLoadErrorMessage: String? {
        get { wordFeature.wordLoadErrorMessage }
        set { wordFeature.wordLoadErrorMessage = newValue }
    }

    // 책 등록 완료 후 홈의 사전 검색 화면을 열기 위한 1회성 요청이다.
    @Published var pendingDictionarySearchPresentationID: UUID?

    // MARK: - Quote, Memo & Review State

    // 현재 열람 중인 책의 문장 목록이다.
    var quotes: [Quote] {
        get { quoteFeature.quotes }
        set { quoteFeature.quotes = newValue }
    }

    // 문장 목록 조회 실패 메시지다.
    var quoteLoadErrorMessage: String? {
        get { quoteFeature.quoteLoadErrorMessage }
        set { quoteFeature.quoteLoadErrorMessage = newValue }
    }

    // 현재 열람 중인 책의 독서 메모 목록이다.
    var readingMemos: [ReadingMemo] {
        get { memoFeature.readingMemos }
        set { memoFeature.readingMemos = newValue }
    }

    // 현재 메모리에 반영된 리뷰 목록이다.
    var reviews: [Review] {
        get { reviewFeature.reviews }
        set { reviewFeature.reviews = newValue }
    }

    var publicBookReviews: [Review] {
        get { reviewFeature.publicBookReviews }
        set { reviewFeature.publicBookReviews = newValue }
    }
    var isPublicReviewLoading: Bool {
        get { reviewFeature.isPublicReviewLoading }
        set { reviewFeature.isPublicReviewLoading = newValue }
    }
    var publicReviewErrorMessage: String? {
        get { reviewFeature.publicReviewErrorMessage }
        set { reviewFeature.publicReviewErrorMessage = newValue }
    }

    // MARK: - App State

    // 사용자 작업 실패 메시지다.
    var operationErrorMessage: String? {
        get { context.operationErrorMessage }
        set { context.operationErrorMessage = newValue }
    }

    // 화면에 보여줄 토스트 상태다.
    var toast: AppToast? {
        get { context.toast }
        set { context.toast = newValue }
    }

    // API에서 401을 받았을 때 로그인 만료 처리를 트리거한다.
    var didReceiveUnauthorized: Bool {
        get { context.didReceiveUnauthorized }
        set { context.didReceiveUnauthorized = newValue }
    }

    // MARK: - Services

    let context: AppContext
    let libraryFeature: BookLibraryViewModel
    let wordFeature: WordViewModel
    let searchFeature: SearchViewModel
    let quoteFeature: QuoteViewModel
    let memoFeature: ReadingMemoViewModel
    let reviewFeature: ReviewViewModel
    private var featureSubscriptions = Set<AnyCancellable>()
    let dependencies: AppDependencies
    let recentSearchRepository: any RecentSearchRepository

    init(dependencies: AppDependencies? = nil, recentSearchRepository: (any RecentSearchRepository)? = nil) {
        let dependencies = dependencies ?? AppDependencies()
        self.dependencies = dependencies
        let context = AppContext()
        self.context = context
        let searchFeature = SearchViewModel(dependencies: dependencies, recentSearchRepository: recentSearchRepository)
        self.searchFeature = searchFeature
        let wordFeature = WordViewModel(repository: dependencies.words, search: searchFeature, context: context)
        self.wordFeature = wordFeature
        self.libraryFeature = BookLibraryViewModel(dependencies: dependencies, words: wordFeature, context: context)
        self.quoteFeature = QuoteViewModel(repository: dependencies.quotes, context: context)
        self.memoFeature = ReadingMemoViewModel(repository: dependencies.memos, context: context)
        self.reviewFeature = ReviewViewModel(repository: dependencies.reviews, context: context)
        self.recentSearchRepository = recentSearchRepository ?? dependencies.recentSearches
        [context.objectWillChange, libraryFeature.objectWillChange, wordFeature.objectWillChange, searchFeature.objectWillChange, quoteFeature.objectWillChange,
         memoFeature.objectWillChange, reviewFeature.objectWillChange].forEach { publisher in
            publisher.sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &featureSubscriptions)
        }
    }

    // MARK: - Current User

    var recentSearchOwnerId: UUID? {
        get { searchFeature.recentSearchOwnerId }
        set { searchFeature.recentSearchOwnerId = newValue }
    }
    var currentUserId: UUID? {
        get { context.currentUserId }
        set { context.currentUserId = newValue }
    }

    private var currentUserNickname: String = "나"
    private var currentUserProfileImageURL: String?

    // MARK: - Common Helpers

    func requestDictionarySearchPresentation() {
        pendingDictionarySearchPresentationID = UUID()
    }

    // 앱 전역 토스트를 표시한다.
    func showToast(_ message: String, style: AppToast.Style = .info) {
        context.showToast(message, style: style)
    }

    // 인증 만료 오류를 감지하고 로그인 만료 상태를 표시한다.
    func handleUnauthorizedIfNeeded(_ error: Error) -> Bool {
        context.handleUnauthorizedIfNeeded(error)
    }

    // 로그인한 사용자 정보를 ViewModel 상태에 반영한다.
    func setCurrentUser(_ user: AuthUser?) {
        currentUserId = user?.id
        currentUserNickname = user?.nickname ?? "나"
        currentUserProfileImageURL = user?.profileImageUrl
        setRecentSearchOwner(userId: user?.id)
    }
}
