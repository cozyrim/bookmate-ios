//
//  BookDetailView.swift
//  BookMate
//
//  Created by 한채림 on 5/14/26.
//

import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BookMateViewModel
    @State private var bookWordSearchText = ""
    
    
    let book: Book // 어떤 책인지
    
    private var savedWordsForBookCount: Int {
        viewModel.savedWords(for: book.id).count
    }
    
    private var filteredWordsForBook: [Word] {
        let words = viewModel.savedWords(for: book.id)
        let trimmed = bookWordSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let filtered = trimmed.isEmpty ? words : words.filter { word in
                word.text.localizedCaseInsensitiveContains(trimmed)
                || word.meaning.localizedCaseInsensitiveContains(trimmed)
                || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
            }
        
        return Array(filtered.reversed())
    } // 현재 책 id와 같은 bookId를 가진 단어만 가져옴
    
    var body: some View {
        ZStack{
            Color("AppBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 24){
                HStack {
                    CircleIconButton(systemName: "chevron.left") {
                        dismiss()
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)

                HStack{
                    BookCoverCell(imageName: book.imageName)
                    
                    VStack(alignment: .leading, spacing: 12){
                        Text("\(book.title)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("\(book.author)")
                            .font(.caption)
                            .foregroundStyle(Color("TextMuted"))
                            .fontWeight(.bold)
                        
                        HStack{
                            Image(systemName: "bookmark")
                            
                            Text("저장된 단어 \(savedWordsForBookCount)개")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color("PrimaryDeep"))
                    }
                    .frame(width: 200, height: 130, alignment: .leading)
                    .padding(.leading, 24)
                    .background(Color("Surface"))
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                }
                
                SearchTextField(searchText: $bookWordSearchText, placeholder: "이 책에서 단어 검색...")

                HStack{
                    Text("최근 추가됨")
                    Spacer()
                    Text("최신순")
                }
                .padding(.horizontal, 24)
                
                if filteredWordsForBook.isEmpty {
                    ContentStateView(
                        type: .empty,
                        iconName: "magnifyingglass",
                        title: bookWordSearchText.isEmpty ? "저장한 단어가 없어요." : "검색 결과가 없어요.",
                        message: bookWordSearchText.isEmpty ? "이 책에서 만난 단어를 저장해보세요." : "다른 단어로 다시 검색해보세요.",
                        buttonTitle: nil,
                        buttonIconName: nil,
                        buttonAction: nil
                    )
                    .padding(.horizontal, 24)
                } else {
                    ForEach(filteredWordsForBook) { word in
                        NavigationLink{
                            WordDetailsView(viewModel: viewModel, word: word)
                        } label: {
                            BookSavedWordCell(text: word.text, partOfSpeech: word.partOfSpeech, meaning: word.meaning)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(.top)
        }
        .navigationBarBackButtonHidden(true)
    }
}
#Preview {
    BookDetailView(viewModel: BookMateViewModel(), book: Book.dummyBooks[0])
}
