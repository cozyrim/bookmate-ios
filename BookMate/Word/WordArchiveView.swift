//
//  WordArchiveView.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct WordArchiveView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @State private var selectedWordToDelete: Word?
    @State private var selectedWordToEdit: Word?
    @State private var selectedWordToMove: Word?
    @State private var isShowingDeleteAlert = false
    @State private var archiveSearchText = ""
    @State private var isShowingBookFilter = false    // 책 바텀 시트
    @State private var isShowingSortOrder = false     // 정렬 바텀 시트
    @Binding var selectedTab: Int

    private var filteredWords: [Word] {
        let trimmed = archiveSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return viewModel.archiveFilteredWords
        }

        return viewModel.archiveFilteredWords.filter { word in
            word.text.localizedCaseInsensitiveContains(trimmed)
                || word.meaning.localizedCaseInsensitiveContains(trimmed)
                || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }
    }

    // 등록된 책에서 중복 없이 카테고리 목록 추출
    private var availableCategories: [String] {
        let all = viewModel.booksOnShelf.map { $0.category }
        return Array(Set(all)).sorted()  // 중복 제거 + 가나다순
    }
    
    

    var body: some View {
        NavigationStack {
            ZStack{
                AppBackgroundView()



                if let errorMessage = viewModel.wordLoadErrorMessage {
                    ContentStateView(
                        type: .error,
                        iconName: "exclamationmark.triangle",
                        title: "단어를 불러오지 못했어요.",
                        message: errorMessage,
                        buttonTitle: "다시 시도하기",
                        buttonIconName: "arrow.clockwise",
                        buttonAction: {
                            Task {
                                await viewModel.loadSavedWords()
                            }
                        }
                    )
                    .padding(.top, 40)

                } else if viewModel.savedWords.isEmpty {
                    ContentStateView(
                        type: .empty,
                        iconName: "book",
                        title: "아직 저장한 단어가 없어요.",
                        message: "지금 읽고 있는 책에서 모르는 단어를 검색해보세요.",
                        buttonTitle: "단어 검색하기",
                        buttonIconName: "magnifyingglass",
                        buttonAction: {
                            viewModel.searchMode = .dictionary
                            viewModel.searchText = ""
                            selectedTab = 0
                        }
                    )
                    .padding(.top, 40)

                } else {
                    ScrollView {
                        VStack {

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Color("TextSecondary"))

                                TextField("저장한 단어 검색...", text: $archiveSearchText)
                                    .submitLabel(.search)
                                    .onSubmit {
                                        let trimmed = archiveSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        BMAnalytics.searchSubmit(
                                            mode: .savedWords,
                                            entryPoint: "word_archive",
                                            queryLength: trimmed.count
                                        )
                                        BMAnalytics.searchCompleted(
                                            mode: .savedWords,
                                            resultCount: filteredWords.count,
                                            entryPoint: "word_archive"
                                        )
                                    }

                                if !archiveSearchText.isEmpty {
                                    Button {
                                        archiveSearchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color("TextMuted").opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(
                                        TapGesture().onEnded {
                                            BMAnalytics.wordCardTap(entryPoint: "word_archive")
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color("Surface"))
                            .clipShape(Capsule())
                            .padding(.horizontal, 24)
                            .padding(.top, 18)

                            categoryChips
                                .padding(.top, 12)
                            
                            filterAndSortBar
                                .padding(.top, 8)
                            
                            
                            

                            if filteredWords.isEmpty {
                                ContentStateView(
                                    type: .empty,
                                    iconName: "magnifyingglass",
                                    title: "검색 결과가 없어요.",
                                    message: "저장한 단어 중 일치하는 단어를 찾지 못했어요.",
                                    buttonTitle: nil,
                                    buttonIconName: nil,
                                    buttonAction: nil
                                )
                                .padding(.horizontal, 24)
                                .padding(.top, 40)
                            } else {
                                ForEach(filteredWords) { word in
                                    let book = viewModel.book(for: word.bookId)
                                    
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
                        .padding(.vertical)
                    }
                }
            }
            .sheet(item: $selectedWordToEdit) { word in
                WordRecordEditSheet(
                    word: viewModel.savedWords.first { $0.id == word.id } ?? word,
                    onSave: { updatedWord in
                        await viewModel.updateWord(updatedWord)
                    }
                )
                .presentationDetents([.height(620)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.clear)
            }
            .sheet(item: $selectedWordToMove) { word in
                let currentWord = viewModel.savedWords.first { $0.id == word.id } ?? word

                MoveWordBookSheet(
                    books: viewModel.booksOnShelf,
                    currentBookId: currentWord.bookId,
                    onSelect: { selectedBook in
                        Task {
                            await viewModel.moveWord(currentWord, to: selectedBook)
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingBookFilter) {
                BookFilterSheet(
                    books: viewModel.booksInSelectedCategory,
                    selectedBookId: viewModel.archiveSelectedBookId,
                    onSelect: { selectedId in
                        viewModel.archiveSelectedBookId = selectedId
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingSortOrder) {
                SortOrderSheet(
                    currentOrder: viewModel.archiveSortOrder,
                    onSelect: { selectedOrder in
                        viewModel.archiveSortOrder = selectedOrder
                    }
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
            .alert("단어를 삭제할까요?", isPresented: $isShowingDeleteAlert) {
                Button("취소", role: .cancel) { }

                Button("삭제", role: .destructive) {
                    guard let selectedWordToDelete else { return }

                    Task {
                        let success = await viewModel.deleteWord(selectedWordToDelete)

                        if success {
                            self.selectedWordToDelete = nil
                        }
                    }
                }
            } message: {
                Text("삭제한 단어는 다시 복구할 수 없습니다.")
            }
            .onAppear {
                BMAnalytics.screenView(.wordArchive)
            }
        }
    }
    
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "전체" 칩
                Button {
                    BMAnalytics.wordFilterTap(filterType: "category_all")
                    viewModel.archiveSelectedCategory = nil
                    viewModel.archiveSelectedBookId = nil  // 카테고리 바뀌면 책 선택도 초기화
                } label: {
                    Text("전체")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.archiveSelectedCategory == nil ? .white : Color("TextPrimary"))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(viewModel.archiveSelectedCategory == nil ? Color("Primary") : Color("SurfaceElevated").opacity(0.96))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color("Border").opacity(0.5), lineWidth: viewModel.archiveSelectedCategory == nil ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
                // 카테고리별 칩
                ForEach(availableCategories, id: \.self) { category in
                    let isSelected = viewModel.archiveSelectedCategory == category
                    Button {
                        BMAnalytics.wordFilterTap(filterType: "category")
                        viewModel.archiveSelectedCategory = isSelected ? nil : category
                        viewModel.archiveSelectedBookId = nil  // 카테고리 바뀌면 책 선택 초기화
                    } label: {
                        Text(category)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color("Primary") : Color("SurfaceElevated").opacity(0.96))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color("Border").opacity(0.5), lineWidth: isSelected ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var filterAndSortBar: some View {
        HStack {
            // 책 선택 버튼
            Button {
                BMAnalytics.wordFilterTap(filterType: "book")
                isShowingBookFilter = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical")
                        .font(.caption)

                    // 선택된 책 이름 표시, 없으면 "전체 책"
                    Text(viewModel.archiveSelectedBookId.flatMap { viewModel.book(for: $0)?.title } ?? "전체 책")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(viewModel.archiveSelectedBookId == nil ? Color("TextSecondary") : Color("Primary"))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color("SurfaceElevated").opacity(0.96))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(viewModel.archiveSelectedBookId == nil ? Color("Border").opacity(0.5) : Color("Primary").opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // 정렬 버튼
            Button {
                BMAnalytics.wordFilterTap(filterType: "sort")
                isShowingSortOrder = true
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.archiveSortOrder.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(Color("TextSecondary"))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color("SurfaceElevated").opacity(0.96))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color("Border").opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }
    
    
    
    
    
    
    
    
    
}

#Preview {
    WordArchiveView(viewModel: BookMateViewModel(), selectedTab: .constant(2))
}
