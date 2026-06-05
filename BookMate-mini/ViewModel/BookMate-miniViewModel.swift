//
//  BookMateViewModel.swift
//  BookMate
//
//  Created by 한채림 on 5/17/26.
//

import SwiftUI
import Combine

// final은 상속을 막음
@MainActor
final class BookMateViewModel: ObservableObject {
    enum SearchMode {
        case dictionary
        case savedWords
    }

    @Published var books: [Book] = []
    // 앱에서 보여줄 책 목록. 지금은 더미 데이터지만, 나중에는 서버에서 받아온 책 목록으로 바뀔 수 있음.

    @Published var savedWords: [Word] = []
    // 사용자가 사전 검색 후 책에 저장한 단어들의 원본 목록.

    @Published var searchText = ""
    // 검색창 TextField에 입력 중인 문자열.

    @Published var searchMode: SearchMode = .dictionary
    // 현재 검색 모드. 사전 API 검색인지, 저장한 단어 검색인지 구분함.

    @Published var dictionarySearchResult: DictionaryEntry?
    // 사전 API에서 최종 검색된 단어 하나. 검색 결과 화면과 저장 화면에서 사용함.

    @Published var savedWordSearchResults: [Word] = []
    // 저장한 단어 검색 모드에서 searchText와 일치하는 단어들만 담는 검색 결과 목록.

    @Published var isLoading = false
    // true면 사전 API 요청 중, false면 현재 요청하지 않는 상태.

    @Published var dictionarySuggestions: [DictionaryEntry] = []
    // 사전 검색 모드에서 검색어를 입력하는 동안 TextField 아래에 보여줄 후보 단어 목록.

    @Published var bookSearchResults: [KakaoBook] = []
    // 새 책 등록할 때 카카오 책 검색에만 관련된 상태.

    @Published var isBookSearchLoading = false

    @Published var bookSearchErrorMessage: String?

    @Published var recentSearches: [String] = []

    @Published var savedBookSearchResults: [Book] = []
    // 책 검색 결과 배열 추가

    @Published var toast: AppToast?
    // toast 상태 추가
    
    @Published var searchErrorMessage: String?
    // 사전 검색, 내 기록 검색처럼 검색 UI에 보여줄 에러.

    @Published var loadErrorMessage: String?
    // 저장한 책/단어를 서버에서 불러올 때 생긴 에러.

    @Published var operationErrorMessage: String?
    // 저장, 수정, 삭제처럼 사용자가 실행한 작업의 실패 에러.
    

    private var recentSearchOwnerId: UUID?

    private var recentSearchsKey: String {
        if let recentSearchOwnerId {
            return "recentDictionarySearches.\(recentSearchOwnerId.uuidString)"
        } else {
            return "recentDictionarySearches.guest"
        }
    }

    private var savedRecentSearches: Bool {
        UserDefaults.standard.object(forKey: "savesRecentSearches") as? Bool ?? true
    }

    private var suggestsSimilarWordsOnFailure: Bool {
        UserDefaults.standard.object(forKey: "suggestsSimilarWordsOnFailure") as? Bool ?? true
    }


    private let kakaoBookSearchService = KakaoBookSearchService()
    private let bookAPIService = BookAPIService()
    private let wordAPIService = WordAPIService()

    private var isRunningForPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "STDICT_API_KEY") as? String else {
            return ""
        }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "$(STDICT_API_KEY)" else {
            return ""
        }

        return trimmedKey
    }

    func saveWord(
        bookId: UUID,
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String
    ) {
        let word = Word(
            text: text,
            meaning: meaning,
            partOfSpeech: partOfSpeech,
            exampleSentence: exampleSentence,
            targetCode: targetCode,
            bookId: bookId
        )

        savedWords.append(word)
    }

    // 검색어가 비어 있으면 검색하지 않음
    // 검색을 시작하면 로딩 표시 켜기
    // 이전 에러 메세지 지우기
    // 이전 검색 결과 지우기


    func performSearch() async {
        switch searchMode {
        case .dictionary:
            savedWordSearchResults = []
            await searchDictionaryEntry()
        case .savedWords:
            dictionarySearchResult = nil
            searchSavedWords()
        }
    }

    /// 앱에 저장된 단어, 책에서 문자열 포함 검색 (로컬만, 네트워크 없음)
    func searchSavedWords() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchErrorMessage = "검색어를 입력해 주세요."
            savedWordSearchResults = []
            savedBookSearchResults = []
            return
        }

        searchErrorMessage = nil

        savedWordSearchResults = savedWords.filter { word in
            word.text.localizedCaseInsensitiveContains(trimmed)
            || word.meaning.localizedCaseInsensitiveContains(trimmed)
            || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }

        savedBookSearchResults = books.filter { book in
                book.title.localizedCaseInsensitiveContains(trimmed)
                    || book.author.localizedCaseInsensitiveContains(trimmed)
                    || book.category.localizedCaseInsensitiveContains(trimmed)
            }

        if savedWordSearchResults.isEmpty && savedBookSearchResults.isEmpty {
            searchErrorMessage = "저장한 단어 또는 책에서 검색 결과가 없습니다."
        }
    }

    // 사전 api에서 단어를 찾아오는 함수
    func searchDictionaryEntry() async {

        let trimmedSearchText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")

        guard !trimmedSearchText.isEmpty else {
            searchErrorMessage = "검색어를 입력해 주세요."
            return
        }

        print("검색 시작:", trimmedSearchText)

        isLoading = true
        searchErrorMessage = nil
        dictionarySearchResult = nil

        let apiKey = apiKey
        guard !apiKey.isEmpty else {
            searchErrorMessage = "API 키가 설정되지 않았습니다."
            isLoading = false
            return
        }

        // 표준국어대사전 api 호출
        // https://stdict.korean.go.kr/api/search.do?key=API_KEY&q=찰나&req_type=json
        do {
            var components = URLComponents(string: "https://stdict.korean.go.kr/api/search.do")!

            components.queryItems = [
                URLQueryItem(name: "key", value: apiKey),
                URLQueryItem(name: "q", value: trimmedSearchText),
                URLQueryItem(name: "req_type", value: "json")
            ]

            guard let url = components.url else {
                searchErrorMessage = "URL을 만들 수 없습니다."
                isLoading = false
                return
            }

            print("요청 URL 생성 완료:", url.host ?? "host 없음")


            let (data, _) = try await URLSession.shared.data(from: url)

            print(String(data: data, encoding: .utf8) ?? "응답 확인 불가")


            let response = try JSONDecoder().decode(StdDictSearchResponse.self, from: data) // 여기서 표준국어대사전 서버가 보내준 json 데이터를 swift 구조체로 변환

            guard let firstItem = response.channel.item.first else {
                searchErrorMessage = "검색 결과가 없습니다."

                if suggestsSimilarWordsOnFailure {
                        await fetchDictionarySuggestions()
                    }

                isLoading = false
                return
            }

            dictionarySearchResult = DictionaryEntry(
                text: firstItem.word.trimmingCharacters(in: .whitespacesAndNewlines),
                meaning: firstItem.sense.definition.trimmingCharacters(in: .whitespacesAndNewlines),
                partOfSpeech: firstItem.pos,
                exampleSentence: nil,
                targetCode: firstItem.targetCode
            )

            addRecentSearch(trimmedSearchText) // 최근 검색어 저장

            isLoading = false

        } catch {
            searchErrorMessage = "검색 중 오류가 발생했습니다."
            isLoading = false
            print(error)
        }
    }


    func fetchDictionarySuggestions() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard searchMode == .dictionary else {
            dictionarySuggestions = []
            return
        }

        guard trimmed.count >= 2 else {
            dictionarySuggestions = []
            return
        }

        let apiKey = apiKey
        guard !apiKey.isEmpty else {
            dictionarySuggestions = []
            return
        }

        do {
            var components = URLComponents(string: "https://stdict.korean.go.kr/api/search.do")!

            components.queryItems = [
                URLQueryItem(name: "key", value: apiKey),
                URLQueryItem(name: "q", value: trimmed),
                URLQueryItem(name: "req_type", value: "json")
            ]

            guard let url = components.url else { return }

            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("후보 검색 상태 코드:", httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                dictionarySuggestions = []
                print("후보 검색 응답이 비어 있음")
                return
            }

            let decodedResponse = try JSONDecoder().decode(StdDictSearchResponse.self, from: data)

            dictionarySuggestions = decodedResponse.channel.item.prefix(5).map { item in
                DictionaryEntry(text: item.word.trimmingCharacters(in: .whitespacesAndNewlines), meaning: item.sense.definition.trimmingCharacters(in: .whitespacesAndNewlines), partOfSpeech: item.pos, exampleSentence: nil, targetCode: item.targetCode)
            }
        } catch {
            dictionarySuggestions = []
            print("사전 후보 검색 실패:", error)
        }

    }

    // 이미 검색 결과로 만들어져 있는 dictionarySearchResult를 저장
    // 찾아온 단어를 내 앱의 저장 목록에 넣는 함수
    func saveDictionaryResult(to bookId: UUID, exampleSentence: String?) async -> Bool {
        // async 함수랑 MainActor 어떻게 작동하는지 공부하기

        guard let dictionarySearchResult else { return false }

        // 검색 결과가 있는지 확인
        let alreadySaved = savedWords.contains {
            $0.bookId == bookId &&
            $0.targetCode == dictionarySearchResult.targetCode
        }

        guard !alreadySaved else { return false } // true면 return

        do {
            let savedWord = try await wordAPIService.saveWord(
                bookId: bookId,
                text: dictionarySearchResult.text,
                meaning: dictionarySearchResult.meaning,
                partOfSpeech: dictionarySearchResult.partOfSpeech,
                exampleSentence: exampleSentence?.isEmpty == true ? nil : exampleSentence,
                targetCode: dictionarySearchResult.targetCode
            )
            savedWords.insert(savedWord, at: 0)
            operationErrorMessage = nil
            return true
        } catch {
            operationErrorMessage = "단어 저장에 실패했습니다."
            print("단어 저장 실패:", error)
            return false
        }
    }


    // 특정 책에 저장된 단어만 골라내는 함수
    func savedWords(for bookId: UUID) -> [Word] {
        savedWords.filter { $0.bookId == bookId}
    }

    // 저장한 단어 불러오기
    func loadSavedWords() async {
        do {
            savedWords = try await wordAPIService.fetchWords()
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = "저장한 단어를 불러오지 못했습니다."
            print("저장 단어 조회 실패:", error)
        }
    }

    // 저장한 책 불러오기
    func loadBooks() async {
        do {
            let fetchedBooks = try await bookAPIService.fetchBooks()

            if !fetchedBooks.isEmpty {
                books = fetchedBooks
            }
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = "책 목록을 불러오지 못했습니다."
            print("책 목록 조회 실패:", error)
        }
    }

    // 책검색
    func searchBooks(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            bookSearchErrorMessage = "책 제목 또는 저자를 입력해 주세요."
            return
        }

        isBookSearchLoading = true
        bookSearchErrorMessage = nil

        do {
            bookSearchResults = try await kakaoBookSearchService.searchBooks(query: trimmed)
        } catch {
            bookSearchResults = []
            bookSearchErrorMessage = "책 검색에 실패했습니다."
        }
        isBookSearchLoading = false
    }

    // 책 저장
    func registerBook(draft: BookRegistrationDraft) async throws -> Book {
        let savedBook = try await bookAPIService.createBook(
            title: draft.title,
            author: draft.author,
            imageName: draft.imageName,
            category: draft.category,
            progress: draft.progress
        )
        books.insert(savedBook, at: 0)
        return savedBook
    }

    // 책 삭제
    func deleteBook(_ book: Book) async -> Bool {
        do {
            try await bookAPIService.deleteBook(id: book.id)

            books.removeAll { $0.id == book.id }
            savedWords.removeAll { $0.bookId == book.id}

            operationErrorMessage = nil
            return true
        } catch {
            operationErrorMessage = "책 삭제에 실패했습니다."
            print("책 삭제 실패:", error)
            return false
        }
    }

    // 단어 삭제
    func deleteWord(_ word: Word) async -> Bool {
        do {
            try await wordAPIService.deleteWord(id: word.id)

            savedWords.removeAll { $0.id == word.id }
            savedWordSearchResults.removeAll { $0.id == word.id }

            operationErrorMessage = nil
            return true
        } catch {
            operationErrorMessage = "단어 삭제에 실패했습니다."
            print("단어 삭제 실패:",  error)
            return false
        }
    }

    // 책 수정
    func updateBook(_ book: Book) async -> Bool {
        print("ViewModel updateBook 받음:", book.id.uuidString, book.title, book.author, book.imageName, book.category)


        if isRunningForPreview {
                if let index = books.firstIndex(where: { $0.id == book.id }) {
                books[index] = book
            }
            operationErrorMessage = nil
                return true
            }

        do {
            let updateBook = try await bookAPIService.updateBook(book)

            if let index = books.firstIndex(where: {$0.id == updateBook.id }) {
                books[index] = updateBook
            }

              operationErrorMessage = nil
              return true
        } catch {
            operationErrorMessage = "책 수정에 실패했습니다."
            print("책 수정 실패:", error)
            return false
        }
    }

    // 단어 수정
    func updateWord(_ word: Word) async -> Bool {
        do {
            let updateWord = try await wordAPIService.updateWord(word)

            if let index = savedWords.firstIndex(where: { $0.id == updateWord.id }) {
                savedWords[index] = updateWord
            }

            if let index = savedWordSearchResults.firstIndex(where: { $0.id == updateWord.id }) {
                savedWordSearchResults[index] = updateWord
            }

            operationErrorMessage = nil
            return true
        } catch {
                operationErrorMessage = "단어 수정에 실패했습니다."
                print("단어 수정 실패:", error)
                return false
        }
    }

    // 다른 책으로 이동 (bookId 수정)
    func moveWord(_ word: Word, to book: Book) async -> Bool {
        let movedWord = Word(
            id: word.id,
            text: word.text,
            meaning: word.meaning,
            partOfSpeech: word.partOfSpeech,
            exampleSentence: word.exampleSentence,
            targetCode: word.targetCode,
            bookId: book.id
        )

        return await updateWord(movedWord)
    }



    func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchsKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            recentSearches = []
            return
        }

        recentSearches = decoded
    }

    func addRecentSearch(_ word: String) {
        guard savedRecentSearches else { return }

        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recentSearches.removeAll() { $0 == trimmed }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(10))

        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentSearchsKey)
        }
    }

    func removeRecentSearch(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        recentSearches.removeAll { $0 == trimmed }

        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentSearchsKey)
        }
    }

    func setRecentSearchOwner(userId: UUID?) {
        recentSearchOwnerId = userId
        loadRecentSearches()
    }

    func showToast(_ message: String, style: AppToast.Style = .info) {
        toast = AppToast(message: message, style: style)
    }
    
}
