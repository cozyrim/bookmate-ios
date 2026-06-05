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
    @Binding var selectedTab: Int

    private var filteredWords: [Word] {
        let trimmed = archiveSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return viewModel.savedWords
        }

        return viewModel.savedWords.filter { word in
            word.text.localizedCaseInsensitiveContains(trimmed)
                || word.meaning.localizedCaseInsensitiveContains(trimmed)
                || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }
    }


    var body: some View {
        NavigationStack {
            ZStack{
                AppBackgroundView()



                if let errorMessage = viewModel.loadErrorMessage {
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

                                if !archiveSearchText.isEmpty {
                                    Button {
                                        archiveSearchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color("TextMuted").opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color("Surface"))
                            .clipShape(Capsule())
                            .padding(.horizontal, 24)
                            .padding(.top, 18)


                            ForEach(filteredWords) { word in
                                let book = viewModel.books.first { $0.id == word.bookId }

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
                    books: viewModel.books,
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
        }
    }
}

#Preview {
    WordArchiveView(viewModel: BookMateViewModel(), selectedTab: .constant(2))
}
