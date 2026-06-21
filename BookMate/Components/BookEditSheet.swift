//
//  BookEditSheet.swift
//  BookMate
//
//  Created by 한채림 on 5/29/26.
//

import SwiftUI

struct BookEditSheet: View {

        @Environment(\.dismiss) private var dismiss

        let book: Book
        let onSave: (String) -> Void

        @State private var selectedCategory: String
        @State private var isSaving = false
        
        private let categories = ["카테고리 선택", "소설", "에세이", "인문", "자기계발", "과학", "기타"]

        init(book: Book, onSave: @escaping (String) -> Void) {
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
                                        .foregroundStyle(Color("TextPrimary").opacity(0.55))
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
                                                    ? Color("TextMuted")
                                                    : Color("PrimaryDeep")
                                )
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal, 18)
                                    .frame(height: 54)
                                    .background(Color("Surface").opacity(0.78))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                Spacer()

                            Button {
                                let categoryToSave = selectedCategory
                                
                                onSave(categoryToSave)
                                
                              
                            } label: {
                                            Text(isSaving ? "저장 중..." : "저장하기")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(Color("PrimaryButtonText"))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 56)
                                                .background(Color("Primary"))
                                                .clipShape(Capsule())
                                        }
                                        .padding(.bottom, 12)
                                    }
                                    .padding(.horizontal, 26)
                                    .background(Color("AppBackground"))
    }
}

#Preview {
    BookEditSheet(book: Book.dummyBooks[0]) { _ in }
}
