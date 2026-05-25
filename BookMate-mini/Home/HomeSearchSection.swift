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
                    .foregroundStyle(.black.opacity(0.6))
                )
                .submitLabel(.search)
                .onSubmit {
                    runSearch()
                }
                // 검색 버튼을 누르지 않아도 입력할 때마다 현재 모드에 맞는 검색 결과가 갱신됨.
                .onChange(of: viewModel.searchText) { _, _ in
                    switch viewModel.searchMode{
                    case .dictionary:
                        Task {
                            await viewModel.fetchDictionarySuggestions()
                        }
                        
                    case .savedWords:
                        viewModel.searchSavedWords()
                    }
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            
            if viewModel.searchMode == .dictionary,
               !viewModel.dictionarySuggestions.isEmpty {
                
                VStack(alignment: .leading, spacing: 8){
                    ForEach(viewModel.dictionarySuggestions, id: \.targetCode) { suggestion in
                        Button {
                            viewModel.searchText = suggestion.text
                            viewModel.dictionarySearchResult = suggestion
                            viewModel.dictionarySuggestions = []
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
                            .foregroundStyle(viewModel.searchMode == .dictionary ? Color.white : Color.black)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(viewModel.searchMode == .dictionary ? Color("Peach") : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color("Peach2"), lineWidth: viewModel.searchMode == .dictionary ? 0 : 2)
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
                            .foregroundStyle(viewModel.searchMode == .savedWords ? Color.white : Color.black)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule().fill(viewModel.searchMode == .savedWords ? Color("Peach") : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color("Peach2"), lineWidth: viewModel.searchMode == .savedWords ? 0 : 2)
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
                    .foregroundStyle(.red)
            }
            
            if viewModel.searchMode == .savedWords {
                ForEach(viewModel.savedWordSearchResults) { word in
                    let book = viewModel.books.first { $0.id == word.bookId}
                    
                    NavigationLink {
                        WordDetails(word: word)
                    } label: {
                        SavedWordListCell(
                            text: word.text,
                            partOfSpeech: word.partOfSpeech,
                            meaning: word.meaning,
                            title: book?.title ?? "책 정보 없음"
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
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.03), radius: 16, x: 0, y:10)
        .navigationDestination(isPresented: $isShowingSearchResult) {
            SearchResultView(viewModel: viewModel) {
                isShowingSearchResult = false
            }
        }
    }
    /// `$viewModel.dictionarySearchResult` 는 Binding 이라서 `await` 할 수 없습니다.
    /// `dictionarySearchResult`는 `performSearch()` / `searchDictionaryEntry()` 안에서 채워집니다.
    private func runSearch() {
        print("검색 실행:", viewModel.searchMode)

        Task { @MainActor in
            await viewModel.performSearch()

            if viewModel.searchMode == .dictionary, viewModel.dictionarySearchResult != nil {
                isShowingSearchResult = true
            }
        }
    }
}
#Preview {
    HomeSearchSection(viewModel: BookMateViewModel())
}
