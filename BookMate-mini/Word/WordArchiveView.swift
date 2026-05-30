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
    
    
    var body: some View {
        NavigationStack {
            ZStack{
                Color.skyblue
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack {
                        ForEach(viewModel.savedWords) { word in
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
    WordArchiveView(viewModel: BookMateViewModel())
}
