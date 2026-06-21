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

    enum SearchMode {
        case dictionary
        case book
        case savedWords
    }

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

    // MARK: - Word & Search State

    // 사용자가 책에 저장한 단어 목록이다.
    @Published var savedWords: [Word] = []

    // 검색창 TextField에 입력 중인 문자열이다.
    @Published var searchText = ""

    // 현재 검색 모드다. 사전 API 검색과 저장 단어 검색을 구분한다.
    @Published var searchMode: SearchMode = .dictionary

    // 사전 API에서 최종 선택된 검색 결과다.
    @Published var dictionarySearchResult: DictionaryEntry?

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

    // MARK: - Quote, Memo & Review State

    // 현재 열람 중인 책의 문장 목록이다.
    @Published var quotes: [Quote] = []

    // 문장 목록 조회 실패 메시지다.
    @Published var quoteLoadErrorMessage: String?

    // 현재 열람 중인 책의 독서 메모 목록이다.
    @Published var readingMemos: [ReadingMemo] = []

    // 현재 메모리에 반영된 리뷰 목록이다.
    @Published var reviews: [Review] = Review.sampleReviews

    @Published var publicBookReviews: [Review] = []
    @Published var isPublicReviewLoading = false
    @Published var publicReviewErrorMessage: String?

    // MARK: - App State

    // 사용자 작업 실패 메시지다.
    @Published var operationErrorMessage: String?

    // 화면에 보여줄 토스트 상태다.
    @Published var toast: AppToast?

    // API에서 401을 받았을 때 로그인 만료 처리를 트리거한다.
    @Published var didReceiveUnauthorized = false

    // MARK: - Services

    let bookPageLookupService = BookPageLookupService()
    let kakaoBookSearchService = KakaoBookSearchService()
    let bookAPIService = BookAPIService()
    let wordAPIService = WordAPIService()
    let quoteAPIService = QuoteAPIService()
    let dictionaryExampleLookupService = DictionaryExampleLookupService()
    let memoAPIService = ReadingMemoAPIService()
    let reviewAPIService = ReviewAPIService()

    // MARK: - Current User

    var recentSearchOwnerId: UUID?
    var currentUserId: UUID?

    private var currentUserNickname: String = "나"
    var inFlightBookRegistrationTasks: [String: Task<Book, Error>] = [:]
    private var currentUserProfileImageURL: String?

    // MARK: - Common Helpers

    // 앱 전역 토스트를 표시한다.
    func showToast(_ message: String, style: AppToast.Style = .info) {
        toast = AppToast(message: message, style: style)
    }

    // 인증 만료 오류를 감지하고 로그인 만료 상태를 표시한다.
    func handleUnauthorizedIfNeeded(_ error: Error) -> Bool {
        if case APIError.unauthorized = error {
            didReceiveUnauthorized = true
            showToast("로그인이 만료됐어요. 다시 로그인해 주세요.", style: .error)
            return true
        }

        return false
    }

    // 로그인한 사용자 정보를 ViewModel 상태에 반영한다.
    func setCurrentUser(_ user: AuthUser?) {
        currentUserId = user?.id
        currentUserNickname = user?.nickname ?? "나"
        currentUserProfileImageURL = user?.profileImageUrl
        setRecentSearchOwner(userId: user?.id)
    }
}
