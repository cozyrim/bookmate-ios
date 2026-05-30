//
//  BookEditSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/29/26.
//

import SwiftUI

struct BookEditSheet: View {

        @Environment(\.dismiss) private var dismiss

        let book: Book
        let onSave: (Book) async -> Bool

        @State private var selectedCategory: String
        @State private var isSaving = false
        
        private let categories = ["카테고리 선택", "소설", "에세이", "인문", "자기계발", "과학", "기타"]

        init(book: Book, onSave: @escaping (Book) async -> Bool) {
            self.book = book
            self.onSave = onSave
            _selectedCategory = State(initialValue: book.category)
        }
        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                        Text("책 수정하기")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 28)
                HStack(spacing: 16) {
                                BookCoverCell(imageName: book.imageName, width: 68)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(book.title)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .lineLimit(2)

                                    Text(book.author)
                                        .font(.caption)
                                        .foregroundStyle(.black.opacity(0.55))
                                }
                            }
                            Text("카테고리")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                
                Menu {
                    ForEach(categories, id:\.self) { category in
                        Button(category){
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                                        Text(selectedCategory)
                                            .foregroundStyle(
                                                    selectedCategory == "카테고리 선택"
                                                    ? .peach
                                                    : Color("PeachRedHeavy")
                                )
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal, 18)
                                    .frame(height: 54)
                                    .background(Color.white.opacity(0.78))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                Spacer()

                            Button {
                                let updatedBook = Book(
                                    id: book.id,
                                    title: book.title,
                                    author: book.author,
                                    imageName: book.imageName,
                                    category: selectedCategory,
                                    progress: book.progress
                                )
                                Task {
                                    isSaving = true
                                    let success = await onSave(updatedBook)
                                    isSaving = false
                                    
                                    if success {
                                        dismiss()
                                    }
                                }
                            } label: {
                                            Text(isSaving ? "저장 중..." : "저장하기")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 56)
                                                .background(Color("Peach"))
                                                .clipShape(Capsule())
                                        }
                                        .padding(.bottom, 12)
                                    }
                                    .padding(.horizontal, 26)
                                    .background(Color.skyblue)
    }
}

#Preview {
    BookEditSheet(book: Book.dummyBooks[0]) { updatedBook in
            print("수정된 카테고리:", updatedBook.category)
            return true
        }
}
