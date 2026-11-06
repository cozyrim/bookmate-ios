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

    enum ArchiveSortOrder: String, CaseIterable {
        case latest = "최신순"
        case oldest = "오래된 순"
        case alphabetical = "가나다순"
    }

    // MARK: - Archive State

    // nil이면 전체 카테고리를 의미한다.
    @Published var archiveSelectedCategory: String? = nil

    // nil이면 전체 책을 의미한다.
    @Published var archiveSelectedBookId: UUID? = nil

    // 단어 아카이브 정렬 기준이다.
    @Published var archiveSortOrder: ArchiveSortOrder = .latest

    // MARK: - Book State

    // 서버에서 불러온 내 책 목록이다.
    @Published var books: [Book] = []

    // 책장 화면 렌더링에 사용하는 책별 진행 상태 목록이다.
    @Published var shelfBooks: [ShelfBook] = ShelfBook.sampleShelfBooks

    // 새 책 등록 시 카카오 책 검색 결과를 담는다.
    @Published var bookSearchResults: [KakaoBook] = []

    // 책 검색 요청 중인지 나타낸다.
    @Published var isBookSearchLoading = false

    // 책 검색 실패 메시지다.
    @Published var bookSearchErrorMessage: String?

    // 책 목록 조회 실패 메시지다.
    @Published var bookLoadErrorMessage: String?

    // 다른 탭에서 책장 안의 특정 책으로 이동해 달라고 요청하는 1회성 상태다.
    @Published var pendingShelfBookPresentationID: UUID?

    // MARK: - Word & Search State

    // 사용자가 책에 저장한 단어 목록이다.
    @Published var savedWords: [Word] = []

    // 검색창 TextField에 입력 중인 문자열이다.
    @Published var searchText = ""

    // 현재 검색 모드다. 사전 API 검색과 저장 단어 검색을 구분한다.
    @Published var searchMode: SearchMode = .dictionary

    // 사전 API에서 최종 선택된 검색 결과다.
    @Published var dictionarySearchResult: DictionaryEntry?

    // 단어 저장 시트 표시 상태다.
    @Published var isWordSaveSheetPresented = false

    // 단어 저장 중 책 등록을 시작했을 때, 등록 완료 후 저장 시트로 돌아갈지 나타낸다.
    @Published var shouldResumeWordSaveAfterBookRegistration = false

    // 책 등록 완료 후 홈 화면 위에 단어 저장 시트를 다시 띄울지 나타낸다.
    @Published var isWordSaveResumeSheetPresented = false

    // 책 등록 후 단어 저장 시트에서 자동 선택할 책 ID다.
    @Published var wordSaveBookIdToSelectAfterRegistration: UUID?

    // 저장 단어 검색 모드에서 보여줄 검색 결과다.
    @Published var savedWordSearchResults: [Word] = []

    // 저장 책 검색 모드에서 보여줄 검색 결과다.
    @Published var savedBookSearchResults: [Book] = []

    // 사전 API 검색 요청 중인지 나타낸다.
    @Published var isLoading = false

    // 사전 검색 실패 시 제안할 후보 단어 목록이다.
    @Published var dictionarySuggestions: [DictionaryEntry] = []

    // 최근 검색어 목록이다.
    @Published var recentSearches: [String] = []

    // 사전 검색, 저장 단어 검색에서 보여줄 오류 메시지다.
    @Published var searchErrorMessage: String?

    // 저장 단어 조회 실패 메시지다.
    @Published var wordLoadErrorMessage: String?

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
    let quoteFeature: QuoteViewModel
    let memoFeature: ReadingMemoViewModel
    let reviewFeature: ReviewViewModel
    private var featureSubscriptions = Set<AnyCancellable>()
    let dependencies: AppDependencies
    var bookRepository: any BookRepository { dependencies.books }
    var wordRepository: any WordRepository { dependencies.words }
    var quoteRepository: any QuoteRepository { dependencies.quotes }
    var memoRepository: any ReadingMemoRepository { dependencies.memos }
    var reviewRepository: any ReviewRepository { dependencies.reviews }
    var bookSearchRepository: any BookSearchRepository { dependencies.bookSearch }
    var bookPageRepository: any BookPageRepository { dependencies.bookPages }
    var dictionaryExampleRepository: any DictionaryExampleRepository { dependencies.dictionaryExamples }
    let recentSearchRepository: any RecentSearchRepository

    init(dependencies: AppDependencies? = nil, recentSearchRepository: (any RecentSearchRepository)? = nil) {
        let dependencies = dependencies ?? AppDependencies()
        self.dependencies = dependencies
        let context = AppContext()
        self.context = context
        self.quoteFeature = QuoteViewModel(repository: dependencies.quotes, context: context)
        self.memoFeature = ReadingMemoViewModel(repository: dependencies.memos, context: context)
        self.reviewFeature = ReviewViewModel(repository: dependencies.reviews, context: context)
        self.recentSearchRepository = recentSearchRepository ?? dependencies.recentSearches
        [context.objectWillChange, quoteFeature.objectWillChange,
         memoFeature.objectWillChange, reviewFeature.objectWillChange].forEach { publisher in
            publisher.sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &featureSubscriptions)
        }
    }

    // MARK: - Current User

    var recentSearchOwnerId: UUID?
    var currentUserId: UUID? {
        get { context.currentUserId }
        set { context.currentUserId = newValue }
    }

    private var currentUserNickname: String = "나"
    var inFlightBookRegistrationTasks: [String: Task<Book, Error>] = [:]
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
