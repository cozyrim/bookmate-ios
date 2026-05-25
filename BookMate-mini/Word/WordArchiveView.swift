//
//  WordArchiveView.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct WordArchiveView: View {
    @ObservedObject var viewModel: BookMateViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(viewModel.savedWords.reversed()) { word in
                        let book = viewModel.books.first { $0.id == word.bookId }

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
                .padding(.vertical)
            }
        }
    }
}

#Preview {
    WordArchiveView(viewModel: BookMateViewModel())
}
