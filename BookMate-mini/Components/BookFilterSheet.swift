//
//  BookFilterSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/8/26.
//

import SwiftUI

struct BookFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // 바텀 시트가 표시할 책 목록 (카테고리 필터 적용된 것)
        let books: [Book]
    
    // 현재 선택된 bookId (없으면 nil = 전체)
        let selectedBookId: UUID?
    
    // 사용자가 선택했을 때 호출할 클로저
        let onSelect: (UUID?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 상단 타이틀
                        Text("책 선택")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                            .padding(.bottom, 20)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    // "전체" 옵션
                                        bookRow(
                                            title: "전체 책",
                                            isSelected: selectedBookId == nil
                                        ) {
                                            onSelect(nil)   // nil = 전체
                                            dismiss()
                                        }
                    Divider()
                                            .padding(.leading, 24)
                    // 책 목록
                                        ForEach(books) { book in
                                            bookRow(
                                                title: book.title,
                                                isSelected: selectedBookId == book.id
                                            ) {
                                                onSelect(book.id)
                                                dismiss()
                                            }
                                            
                                            Divider()
                                                .padding(.leading, 24)
                }
            }
        }
    }
        .presentationBackground(Color("AppBackground"))
}

    // 행 하나를 그리는 서브뷰
    private func bookRow(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button {
                    onTap()
                } label: {
                    HStack {
                        Text(title)
                            .font(.callout)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? Color("Primary") : Color("TextPrimary"))
                        
                        Spacer()
                        
                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color("Primary"))
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 18)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
    }
    
    
    
#Preview {
    BookFilterSheet(
            books: Book.dummyBooks,
            selectedBookId: nil,
            onSelect: { _ in }
        )
}
