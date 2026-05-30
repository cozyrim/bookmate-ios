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
        viewModel.books.first { $0.id == currentWord.bookId}
    }
    
    
    
    var body: some View {
        ZStack{
            Color.skyblue
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color("Peach"))
                        .clipShape(Capsule())
                        .shadow(color: Color("Peach").opacity(0.28), radius: 14, x: 0, y: 8)
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
        .navigationBarBackButtonHidden(true)
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
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.78))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button {
                print("북마크")
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.68))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            
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
            .background(Color.white.opacity(0.18))
            .clipShape(Circle())
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
    }
    
    private var wordHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Text(currentWord.text)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.black.opacity(0.82))
                
                Text("저장됨")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("GreenHeavy"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Green"))
                    .clipShape(Capsule())
            }
            
            Text(currentWord.partOfSpeech)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.blue.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
            
            Text(currentWord.meaning)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundStyle(.black.opacity(0.78))
                .lineSpacing(6)
            
        }
    }
    
    private var exampleSentenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("책 속 문장")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.black.opacity(0.82))
            
            Text(currentWord.exampleSentence?.isEmpty == false ? currentWord.exampleSentence! : "아직 저장한 책 속 문장이 없어요.")
                .font(.title3)
                .foregroundStyle(.black.opacity(currentWord.exampleSentence == nil ? 0.42 : 0.78))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(Color.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        }
    }
    
    
    private var savedBookSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("저장한 책")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.black.opacity(0.82))
            
            if let relatedBook {
                NavigationLink {
                    BookDetailView(viewModel: viewModel, book: relatedBook)
                } label: {
                    HStack(spacing: 14) {
                        BookCoverCell(imageName: relatedBook.imageName, width: 46)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(relatedBook.title)
                                .font(.headline)
                                .foregroundStyle(.black.opacity(0.82))
                                .lineLimit(1)
                            
                            Text(relatedBook.author)
                                .font(.caption)
                                .foregroundStyle(.black.opacity(0.55))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.callout)
                            .foregroundStyle(.black.opacity(0.45))
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
            }else {
                Text("연결된 책 정보를 찾을 수 없습니다.")
                    .font(.callout)
                    .foregroundStyle(.black.opacity(0.55))
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
