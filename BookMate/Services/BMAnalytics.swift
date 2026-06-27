//
//  BMAnalytics.swift
//  BookMate
//
//  Created by Codex on 6/27/26.
//

import FirebaseAnalytics
import Foundation

enum BMAnalytics {
    enum Screen: String {
        case home
        case bookShelf = "book_shelf"
        case wordArchive = "word_archive"
        case library
        case profile
        case bookSearch = "book_search"
        case dictionaryResult = "dictionary_result"
        case profileEdit = "profile_edit"
    }

    static func setUser(_ user: AuthUser?) {
        Analytics.setUserID(user?.id.uuidString)
    }

    static func screenView(_ screen: Screen) {
        log(
            AnalyticsEventScreenView,
            [
                AnalyticsParameterScreenName: screen.rawValue,
                AnalyticsParameterScreenClass: screen.rawValue
            ]
        )
    }

    static func tabTap(index: Int, name: String) {
        log("tab_tap", [
            "tab_index": index,
            "tab_name": name
        ])
    }

    static func signUpCompleted(method: String) {
        log(AnalyticsEventSignUp, [
            AnalyticsParameterMethod: method
        ])
    }

    static func signUpFailed(method: String, error: Error) {
        log("sign_up_failed", [
            AnalyticsParameterMethod: method,
            "error_code": errorCode(error)
        ]) 
    }

    static func loginCompleted(method: String) {
        log(AnalyticsEventLogin, [
            AnalyticsParameterMethod: method
        ])
    }

    static func loginFailed(method: String, error: Error) {
        log("login_failed", [
            AnalyticsParameterMethod: method,
            "error_code": errorCode(error)
        ])
    }

    static func logoutCompleted() {
        log("logout_completed")
    }

    static func homeSearchImpression(mode: BookMateViewModel.SearchMode, hasRecentSearches: Bool) {
        log("home_search_impression", [
            "search_mode": mode.analyticsValue,
            "has_recent_searches": yesNo(hasRecentSearches)
        ])
    }

    static func homeSearchTap(mode: BookMateViewModel.SearchMode) {
        log("home_search_tap", [
            "search_mode": mode.analyticsValue
        ])
    }

    static func searchModeTap(_ mode: BookMateViewModel.SearchMode, entryPoint: String) {
        log("search_mode_tap", [
            "search_mode": mode.analyticsValue,
            "entry_point": entryPoint
        ])
    }

    static func searchSubmit(mode: BookMateViewModel.SearchMode, entryPoint: String, queryLength: Int) {
        log("search_submit", [
            "search_mode": mode.analyticsValue,
            "entry_point": entryPoint,
            "query_length": queryLength
        ])
    }

    static func searchCompleted(mode: BookMateViewModel.SearchMode, resultCount: Int, entryPoint: String = "api") {
        log("search_completed", [
            "search_mode": mode.analyticsValue,
            "entry_point": entryPoint,
            "result_count": resultCount
        ])
    }

    static func searchFailed(mode: BookMateViewModel.SearchMode, reason: String, entryPoint: String = "api") {
        log("search_failed", [
            "search_mode": mode.analyticsValue,
            "entry_point": entryPoint,
            "reason": reason
        ])
    }

    static func searchResultImpression(type: String, resultCount: Int, entryPoint: String) {
        log("search_result_impression", [
            "result_type": type,
            "result_count": resultCount,
            "entry_point": entryPoint
        ])
    }

    static func searchResultTap(type: String, entryPoint: String, rank: Int? = nil) {
        var parameters: [String: Any] = [
            "result_type": type,
            "entry_point": entryPoint
        ]

        if let rank {
            parameters["rank"] = rank
        }

        log("search_result_tap", parameters)
    }

    static func bookCreateEntryTap(entryPoint: String) {
        log("book_create_entry_tap", [
            "entry_point": entryPoint
        ])
    }

    static func bookCreated(source: String, hasISBN: Bool, hasTotalPages: Bool) {
        log("book_created", [
            "source": source,
            "has_isbn": yesNo(hasISBN),
            "has_total_pages": yesNo(hasTotalPages)
        ])
    }

    static func bookDeleted() {
        log("book_deleted")
    }

    static func bookCreateFailed(source: String, reason: String) {
        log("book_create_failed", [
            "source": source,
            "reason": reason
        ])
    }

    static func bookCardTap(entryPoint: String, readingStatus: ReadingStatus?) {
        log("book_card_tap", [
            "entry_point": entryPoint,
            "reading_status": readingStatus?.rawValue ?? "unknown"
        ])
    }

    static func readingProgressUpdated(progressBucket: String, readingStatus: ReadingStatus?) {
        log("reading_progress_update", [
            "progress_bucket": progressBucket,
            "reading_status": readingStatus?.rawValue ?? "unknown"
        ])
    }

    static func saveWordSheetOpen(hasBooks: Bool, bookCount: Int, entryPoint: String) {
        log("save_word_sheet_open", [
            "has_books": yesNo(hasBooks),
            "book_count_bucket": countBucket(bookCount),
            "entry_point": entryPoint
        ])
    }

    static func saveWordButtonTap(hasSelectedBook: Bool, hasBooks: Bool) {
        log("save_word_button_tap", [
            "has_selected_book": yesNo(hasSelectedBook),
            "has_books": yesNo(hasBooks)
        ])
    }

    static func wordSaved(hasExampleSentence: Bool) {
        log("word_saved", [
            "has_example_sentence": yesNo(hasExampleSentence)
        ])
    }

    static func wordSaveFailed(reason: String) {
        log("word_save_failed", [
            "reason": reason
        ])
    }

    static func wordCardTap(entryPoint: String) {
        log("word_card_tap", [
            "entry_point": entryPoint
        ])
    }

    static func wordFilterTap(filterType: String) {
        log("word_filter_tap", [
            "filter_type": filterType
        ])
    }

    static func wordDeleted() {
        log("word_deleted")
    }

    static func wordUpdated(action: String) {
        log("word_updated", [
            "action": action
        ])
    }

    static func sentenceSaved(hasPage: Bool, hasMemo: Bool) {
        log("sentence_saved", [
            "has_page": yesNo(hasPage),
            "has_memo": yesNo(hasMemo)
        ])
    }

    static func sentenceUpdated() {
        log("sentence_updated")
    }

    static func sentenceDeleted() {
        log("sentence_deleted")
    }

    static func reviewSaved(hasRating: Bool, hasContent: Bool, isPublic: Bool) {
        log("review_saved", [
            "has_rating": yesNo(hasRating),
            "has_content": yesNo(hasContent),
            "is_public": yesNo(isPublic)
        ])
    }

    static func profileUpdated(changedFields: [String], isPublic: Bool) {
        log("profile_updated", [
            "changed_fields": changedFields.sorted().joined(separator: ","),
            "is_public": yesNo(isPublic)
        ])
    }

    static func profileSaveTap(canSave: Bool) {
        log("profile_save_tap", [
            "can_save": yesNo(canSave)
        ])
    }

    static func profileUpdateFailed(error: Error) {
        log("profile_update_failed", [
            "error_code": errorCode(error)
        ])
    }

    static func profileImageChanged(source: String) {
        log("profile_image_changed", [
            "source": source
        ])
    }

    static func profileImageUploadFailed(error: Error) {
        log("profile_image_upload_failed", [
            "error_code": errorCode(error)
        ])
    }

    static func miniRoomThemeUpdated(theme: String) {
        log("miniroom_theme_updated", [
            "theme": theme
        ])
    }

    private static func log(_ name: String, _ parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    private static func yesNo(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    private static func countBucket(_ count: Int) -> String {
        switch count {
        case 0:
            return "0"
        case 1...3:
            return "1_3"
        case 4...10:
            return "4_10"
        default:
            return "11_plus"
        }
    }

    private static func errorCode(_ error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "unauthorized"
        case APIError.invalidResponse:
            return "invalid_response"
        case APIError.badStatusCode(let statusCode):
            return "bad_status_\(statusCode)"
        case let urlError as URLError:
            return "url_\(urlError.code.rawValue)"
        default:
            return "unknown"
        }
    }
}

extension BookMateViewModel.SearchMode {
    var analyticsValue: String {
        switch self {
        case .dictionary:
            return "dictionary"
        case .book:
            return "book"
        case .savedWords:
            return "saved_records"
        }
    }
}
