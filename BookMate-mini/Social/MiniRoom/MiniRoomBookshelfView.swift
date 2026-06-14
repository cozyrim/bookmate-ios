//
//  MiniRoomBookshelfView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomBookshelfView: View {
    let books: [Book]
    let onBookTap: (Book) -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
                    Color(red: 110/255, green: 75/255, blue: 50/255)
                        .frame(height: 180)
                        .shadow(color: .black.opacity(0.25), radius: 10, y: -5)

                    Rectangle()
                        .fill(Color(red: 160/255, green: 110/255, blue: 75/255))
                        .frame(height: 25)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            if books.isEmpty {
                                ForEach(0..<4, id: \.self) { _ in
                                    BookCoverCell(imageName: "bookPlaceholder", width: 90)
                                }
                            } else {
                                ForEach(books) { book in
                                    Button {
                                        onBookTap(book)
                                    } label: {
                                        BookCoverCell(imageName: book.imageName, width: 90)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 25)
                    }
        }
    }
}
