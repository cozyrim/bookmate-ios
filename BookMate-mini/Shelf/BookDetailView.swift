//
//  BookDetailView.swift
//  BookMate
//
//  Created by 한채림 on 5/14/26.
//

import SwiftUI

struct BookDetailView: View {
    @ObservedObject var viewModel: BookMateViewModel
    
    let book: Book // 어떤 책인지
    
    private var savedWordsForBook: [Word] {
        Array(viewModel.savedWords(for: book.id).reversed())
    } // 현재 책 id와 같은 bookId를 가진 단어만 가져옴
    
    var body: some View {
        ZStack{
            Color("AppBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 24){
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
                            
                            Text("저장된 단어 \(savedWordsForBook.count)개")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color("PrimaryDeep"))
                    }
                    .frame(width: 200, height: 130, alignment: .leading)
                    .padding(.leading, 24)
                    .background(Color("Surface"))
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                }
                
                SearchTextField(searchText: $viewModel.searchText, placeholder: "사전에서 단어 검색...") {
                    viewModel.searchSavedWords()
                }
                
                HStack{
                    Text("최근 추가됨")
                    Spacer()
                    Text("최신순")
                }
                .padding(.horizontal, 24)
                
                ForEach(savedWordsForBook) { word in
                    NavigationLink{
                        WordDetailsView(viewModel: viewModel, word: word)
                    } label: {
                        BookSavedWordCell(text: word.text, partOfSpeech: word.partOfSpeech, meaning: word.meaning)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.top)
        }
    }
}
#Preview {
    BookDetailView(viewModel: BookMateViewModel(), book: Book.dummyBooks[0])
}
