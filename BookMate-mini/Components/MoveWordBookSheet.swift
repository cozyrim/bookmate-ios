//
//  MoveWordBookSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/29/26.
//

import SwiftUI

struct MoveWordBookSheet: View {
    @Environment(\.dismiss) private var dismiss

        let books: [Book]
        let currentBookId: UUID
        let onSelect: (Book) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("다른 책으로 이동")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 24)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(books) { book in
                        Button {
                            onSelect(book)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                BookCoverCell(imageName: book.imageName, width: 44)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.headline)
                                    
                                    Text(book.author)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                if book.id == currentBookId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color("Primary"))
                                }
                            }
                            .padding(14)
                                                        .background(Color("Surface").opacity(0.9))
                                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                                    }
                                                    .buttonStyle(.plain)
                                                    .disabled(book.id == currentBookId)
                        }
                    }
                }
            }
        .padding(.horizontal, 24)
        .background(Color("AppBackground"))
    
    }
}

#Preview {
    MoveWordBookSheet(
        books: Book.dummyBooks,
                currentBookId: Book.dummyBooks[0].id,
                onSelect: { _ in }
    )
}
