//
//  WordDetails.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

// 단어 상세 화면
// 수정 버튼 누르면 sheet 띄움
// 수정된 Word를 ViewModel에 저장


import SwiftUI

struct WordDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: BookMateViewModel
    let word: Word
    
    @State private var isShowingDeleteAlert = false
    
    @State private var isShowingEditSheet = false
    
    @State private var isShowingMoveBookSheet = false
    
    private var currentWord: Word {
        viewModel.savedWords.first { $0.id == word.id} ?? word
    }
    
    private var relatedBook: Book? {
        viewModel.book(for: currentWord.bookId)
    }
    
    
    
    var body: some View {
        ZStack{
            Color("AppBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 0){
                topBar
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        wordHeader
                        exampleSentenceSection
                        savedBookSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
            }
            
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button { isShowingEditSheet = true } label: {
                Label("기록 수정하기", systemImage: "pencil")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryButtonText"))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color("Primary"), in: .rect(cornerRadius: ReadingStyle.fieldRadius))
            }
            .accessibilityIdentifier("word.detail.edit")
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .preference(key: CompactTabBarHiddenKey.self, value: true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $isShowingEditSheet) {
            WordRecordEditSheet(word: currentWord,
                                onSave: { updateWord in
    
                    await viewModel.updateWord(updateWord)
            }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color("AppBackground"))
        }
        .sheet(isPresented: $isShowingMoveBookSheet) {
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
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
        .alert("단어를 삭제할까요?", isPresented: $isShowingDeleteAlert) {
            Button("취소", role: .cancel) { }
            
            Button("삭제", role: .destructive) {
                Task {
                    let success = await viewModel.deleteWord(currentWord)
                    
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("삭제한 단어는 다시 복구할 수 없습니다.")
        }
    }
    
    private var topBar: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left") {
                dismiss()
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("뒤로")

            Spacer()
            
            MoreOptionsMenu(
                onEdit: {
                    isShowingEditSheet = true
                }, onDelete: {
                    isShowingDeleteAlert = true
                }, onMove: {
                    isShowingMoveBookSheet = true
                }
            )
            .frame(width: 44, height: 44)
            .background(Color("Surface").opacity(0.18))
            .clipShape(Circle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentWord.text)
                .font(.largeTitle.bold())
                .foregroundStyle(Color("TextPrimary"))
            
            PartOfSpeechBadge(
                text: currentWord.partOfSpeech,
                font: .caption,
                horizontalPadding: 10,
                verticalPadding: 4
            )
            
            Text(currentWord.meaning)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundStyle(Color("TextPrimary"))
                .lineSpacing(6)
            
        }
    }
    
    private var exampleSentenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("책 속 문장").font(.headline).foregroundStyle(Color("TextPrimary"))
            if let sentence = currentWord.exampleSentence, !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(sentence).font(.body).foregroundStyle(Color("TextPrimary"))
                    .lineSpacing(5).textSelection(.enabled)
            } else {
                Text("기록 수정에서 이 단어를 만난 문장을 남겨보세요.")
                    .font(.body).foregroundStyle(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var savedBookSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
            Text("저장한 책")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))
            
            if let relatedBook {
                NavigationLink {
                    BookDetailView(viewModel: viewModel, book: relatedBook)
                } label: {
                    HStack(spacing: 14) {
                        BookCoverCell(imageName: relatedBook.imageName, width: 54, trailingPadding: 0)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(relatedBook.title)
                                .font(.headline)
                                .foregroundStyle(Color("TextPrimary"))
                                .lineLimit(1)
                            
                            Text(relatedBook.author)
                                .font(.caption)
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.callout)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }else {
                Text("연결된 책 정보를 찾을 수 없습니다.")
                    .font(.callout)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
    }
}

#Preview {
    WordDetailsView(
        viewModel: BookMateViewModel(),
        word: Word.sampleWords[0]
    )
}
