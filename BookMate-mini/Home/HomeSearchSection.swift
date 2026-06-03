//
//  HomeSearchSection.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct HomeSearchSection: View {
    @ObservedObject var viewModel: BookMateViewModel
    @State private var isShowingSearchResult = false
    @State private var selectedWordToDelete: Word?
    @State private var selectedWordToEdit: Word?
    @State private var selectedWordToMove: Word?
    @State private var isShowingDeleteAlert = false
    
    private func searchRecentWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        viewModel.searchMode = .dictionary
            viewModel.searchText = trimmed
            viewModel.dictionarySuggestions = []
            viewModel.dictionarySearchResult = nil
            viewModel.errorMessage = nil
            viewModel.isLoading = true
        
        withAnimation(.easeInOut(duration: 0.2)) {
                isShowingSearchResult = true
            }
        
        Task { @MainActor in
                await viewModel.performSearch()
            }
    }
    
    private func clearSearchText() {
        viewModel.searchText = ""
        viewModel.dictionarySuggestions = []
        viewModel.savedWordSearchResults = []
        viewModel.dictionarySearchResult = nil
        viewModel.errorMessage = nil
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            HStack{
                Button {
                    runSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                
                TextField(
                    
                    "",
                    text: $viewModel.searchText,
                    prompt: Text(
                        viewModel.searchMode == .dictionary
                        ? "사전에서 단어 검색..."
                        : "저장한 단어 검색..."
                    )
                    .foregroundStyle(Color("TextPrimary").opacity(0.6))
                )
                
                
                .submitLabel(.search)
                .onSubmit {
                    runSearch()
                }
                // 검색 버튼을 누르지 않아도 입력할 때마다 현재 모드에 맞는 검색 결과가 갱신됨.
                .onChange(of: viewModel.searchText) { _, newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if trimmed.isEmpty {
                            viewModel.dictionarySuggestions = []
                            viewModel.savedWordSearchResults = []
                            viewModel.dictionarySearchResult = nil
                            viewModel.errorMessage = nil
                            return
                        }
                    
                    switch viewModel.searchMode{
                    case .dictionary:
                        Task {
                            await viewModel.fetchDictionarySuggestions()
                        }
                        
                    case .savedWords:
                        viewModel.searchSavedWords()
                    }
                }
                if !viewModel.searchText.isEmpty {
                    Button {
                        clearSearchText()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color("TextMuted").opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color("Surface").opacity(0.82))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color("Border").opacity(0.55), lineWidth: 1)
            }
            .shadow(color: Color("Shadow").opacity(0.035), radius: 10, x: 0, y: 4)
            
            if viewModel.searchMode == .dictionary,
               viewModel.searchText.isEmpty,
               !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("최근 검색어")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.recentSearches, id: \.self) { recentWord in
                                HStack(spacing: 6) {
                                    Button {
                                        searchRecentWord(recentWord)
                                    } label: {
                                        Text(recentWord)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color("TextSecondary"))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        viewModel.removeRecentSearch(recentWord)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color("TextSecondary").opacity(0.55))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color("Surface").opacity(0.82))
                                .clipShape(Capsule())
                                .shadow(color: Color("Shadow").opacity(0.04), radius: 6, x: 0, y: 2)

                                
                                
                                
                            }
                        }
                    }
                }
            }
            
            
            
            
            if viewModel.searchMode == .dictionary,
               !viewModel.dictionarySuggestions.isEmpty {
                
                VStack(alignment: .leading, spacing: 8){
                    ForEach(viewModel.dictionarySuggestions, id: \.targetCode) { suggestion in
                        Button {
                            viewModel.searchText = suggestion.text
                            viewModel.dictionarySearchResult = suggestion
                            viewModel.dictionarySuggestions = []
                            
                            viewModel.addRecentSearch(suggestion.text)
                            
                            isShowingSearchResult = true
                            
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.text)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                
                                Text(suggestion.meaning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            
            VStack(alignment: .leading){
                Text("선택한 모드")
                    .font(.callout)
                    .padding(.horizontal, 1)
                
                
                HStack(spacing: 12){
                    Button {
                        viewModel.searchMode = .dictionary
                        runSearch()
                    } label: {
                        Text("사전 검색")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.searchMode == .dictionary ? .white : Color("TextPrimary"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(viewModel.searchMode == .dictionary ? Color("Primary") : Color("Surface"))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color("PrimarySoft"), lineWidth: viewModel.searchMode == .dictionary ? 0 : 2)
                            )
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button {
                        viewModel.searchMode = .savedWords
                        runSearch()
                    } label: {
                        Text("내 단어 검색")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.searchMode == .savedWords ? .white : Color("TextPrimary"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule().fill(viewModel.searchMode == .savedWords ? Color("Primary") : Color("Surface"))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color("PrimarySoft"), lineWidth: viewModel.searchMode == .savedWords ? 0 : 2)
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(viewModel.isLoading)
                    Spacer()
                }
            }
            if viewModel.isLoading {
                ProgressView("검색 중...")
                    .font(.caption)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color("Error"))
            }
            
            if viewModel.searchMode == .savedWords {
                ForEach(viewModel.savedWordSearchResults) { word in
                    let book = viewModel.books.first { $0.id == word.bookId}
                    
                    NavigationLink {
                        WordDetailsView(viewModel: viewModel, word: word)
                    } label: {
                        SavedWordListCell(
                            text: word.text,
                            partOfSpeech: word.partOfSpeech,
                            meaning: word.meaning,
                            title: book?.title ?? "책 정보 없음",
                            onEdit: {
                                selectedWordToEdit = word
                            },
                            onDelete: {
                                selectedWordToDelete = word
                                isShowingDeleteAlert = true
                            },
                            onMove: {
                                selectedWordToMove = word
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [
                    Color("AppBackgroundSoft").opacity(0.82),
                    Color("Surface").opacity(0.94),
                    Color("Surface").opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28,
                topTrailingRadius: 0
            )
        )
        .shadow(color: Color("Shadow").opacity(0.03), radius: 16, x: 0, y:10)
        .navigationDestination(isPresented: $isShowingSearchResult) {
            SearchResultView(viewModel: viewModel) {
                isShowingSearchResult = false
            }
        }
        .onChange(of: isShowingSearchResult) { _, isShowing in
            if !isShowing {
                clearDictionarySearchState()
            }
        }
    }
        private func clearDictionarySearchState() {
            guard viewModel.searchMode == .dictionary else { return }

            viewModel.searchText = ""
            viewModel.dictionarySuggestions = []
            viewModel.dictionarySearchResult = nil
            viewModel.errorMessage = nil
            viewModel.isLoading = false
        }
        
        
        
    /// `$viewModel.dictionarySearchResult` 는 Binding 이라서 `await` 할 수 없습니다.
    /// `dictionarySearchResult`는 `performSearch()` / `searchDictionaryEntry()` 안에서 채워집니다.
    private func runSearch() {
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
                viewModel.errorMessage = "검색어를 입력해 주세요."
                return
            }
        
        viewModel.dictionarySuggestions = []
        
        switch viewModel.searchMode {
        case .dictionary:
            viewModel.dictionarySearchResult = nil
            viewModel.errorMessage = nil
            viewModel.isLoading = true
            
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingSearchResult = true
            }
            
            Task { @MainActor in
                await viewModel.performSearch()
            }
            
        case .savedWords:
            Task { @MainActor in
                await viewModel.performSearch()
            }
        }
    }
    
    
    
    
    
    
}
#Preview {
    HomeSearchSection(viewModel: BookMateViewModel())
}
