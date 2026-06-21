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
                    VStack(alignment: .leading, spacing: 28) {
                        wordHeader
                        exampleSentenceSection
                        savedBookSection
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 34)
                    .padding(.bottom, 120)
                }
            }
            
            VStack {
                Spacer()
                
                Button {
                    isShowingEditSheet = true
                } label: {
                    Label("기록 수정하기", systemImage: "pencil")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color("Primary"))
                        .clipShape(Capsule())
                        .shadow(color: Color("Primary").opacity(0.28), radius: 14, x: 0, y: 8)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            WordRecordEditSheet(word: currentWord,
                                onSave: { updateWord in
    
                    await viewModel.updateWord(updateWord)
            }
            )
            .presentationDetents([.height(620)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.clear)
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
            .frame(width: 50, height: 50)
            
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
            .frame(width: 50, height: 50)
            .background(Color("Surface").opacity(0.18))
            .clipShape(Circle())
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
    }
    
    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(currentWord.text)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color("TextPrimary").opacity(0.82))
            
            Text(currentWord.partOfSpeech)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Color("Primary").opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("Surface").opacity(0.18))
                .clipShape(Capsule())
            
            Text(currentWord.meaning)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundStyle(Color("TextPrimary").opacity(0.78))
                .lineSpacing(6)
            
        }
    }
    
    private var exampleSentenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("책 속 문장")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary").opacity(0.82))
            
            Text(currentWord.exampleSentence?.isEmpty == false ? currentWord.exampleSentence! : "아직 저장한 책 속 문장이 없어요.")
                .font(.title3)
                .foregroundStyle(Color("TextPrimary").opacity(currentWord.exampleSentence == nil ? 0.42 : 0.78))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(Color("Surface").opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color("Shadow").opacity(0.05), radius: 12, x: 0, y: 6)
        }
    }
    
    
    private var savedBookSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("저장한 책")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary").opacity(0.82))
            
            if let relatedBook {
                NavigationLink {
                    BookDetailView(viewModel: viewModel, book: relatedBook)
                } label: {
                    HStack(spacing: 14) {
                        BookCoverCell(imageName: relatedBook.imageName, width: 46)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(relatedBook.title)
                                .font(.headline)
                                .foregroundStyle(Color("TextPrimary").opacity(0.82))
                                .lineLimit(1)
                            
                            Text(relatedBook.author)
                                .font(.caption)
                                .foregroundStyle(Color("TextPrimary").opacity(0.55))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.callout)
                            .foregroundStyle(Color("TextPrimary").opacity(0.45))
                    }
                    .padding(16)
                    .background(Color("Surface").opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
            }else {
                Text("연결된 책 정보를 찾을 수 없습니다.")
                    .font(.callout)
                    .foregroundStyle(Color("TextPrimary").opacity(0.55))
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
