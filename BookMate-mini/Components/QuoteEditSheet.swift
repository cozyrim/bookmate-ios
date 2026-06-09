//
//  QuoteEditSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import SwiftUI

struct QuoteEditSheet: View {
    @Environment(\.dismiss) private var dismiss
        @ObservedObject var viewModel: BookMateViewModel
        let quote: Quote
        @State private var editedText: String = ""
        @State private var editedPageText: String = ""
        @State private var editedMemo: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 24) {
                                        // 구절 내용
                                                                VStack(alignment: .leading, spacing: 8) {
                                                                    Text("구절")
                                                                        .font(.subheadline)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundStyle(Color("TextMuted"))
                                                                    TextEditor(text: $editedText)
                                                                        .scrollContentBackground(.hidden)
                                                                        .padding(16)
                                                                        .frame(minHeight: 140)
                                                                        .background(Color("Surface"))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                                        .overlay(
                                                                            RoundedRectangle(cornerRadius: 16)
                                                                                .stroke(Color("TextMuted").opacity(0.2), lineWidth: 1)
                                                                        )
                                                                }
                                        
                                        // 페이지
                                                                VStack(alignment: .leading, spacing: 8) {
                                                                    Text("페이지")
                                                                        .font(.subheadline)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundStyle(Color("TextMuted"))
                                                                    TextField("예) 42", text: $editedPageText)
                                                                        .keyboardType(.numberPad)
                                                                        .padding(16)
                                                                        .background(Color("Surface"))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                                        .overlay(
                                                                            RoundedRectangle(cornerRadius: 16)
                                                                                .stroke(Color("TextMuted").opacity(0.2), lineWidth: 1)
                                                                        )
                                                                }
                                        
                                        // 메모
                                                                VStack(alignment: .leading, spacing: 8) {
                                                                    Text("메모 (선택)")
                                                                        .font(.subheadline)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundStyle(Color("TextMuted"))
                                                                    TextEditor(text: $editedMemo)
                                                                        .scrollContentBackground(.hidden)
                                                                        .padding(16)
                                                                        .frame(minHeight: 100)
                                                                        .background(Color("Surface"))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                                        .overlay(
                                                                            RoundedRectangle(cornerRadius: 16)
                                                                                .stroke(Color("TextMuted").opacity(0.2), lineWidth: 1)
                                                                        )
                                                                }
                                        
                                        // 저장 버튼
                                                                Button {
                                                                    saveQuote()
                                                                } label: {
                                                                    Text("수정 저장")
                                                                        .font(.headline)
                                                                        .foregroundStyle(.white)
                                                                        .frame(maxWidth: .infinity)
                                                                        .padding(.vertical, 16)
                                                                        .background(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                                                    ? Color("TextMuted").opacity(0.4)
                                                                                    : Color("Primary"))
                                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                                }
                                                                .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                                            }
                                                            .padding(24)
                                                        }
                                                    }
                                                    .navigationTitle("구절 수정")
                                                    .navigationBarTitleDisplayMode(.inline)
                                                    .toolbar {
                                                        ToolbarItem(placement: .cancellationAction) {
                                                            Button("취소") { dismiss() }
                                                        }
                                                    }
                                                }
        .onAppear {
                    editedText     = quote.text
                    editedPageText = quote.page.map { String($0) } ?? ""
                    editedMemo     = quote.memo ?? ""
                }
            }
    
    private func saveQuote() {
            let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return }
            let updatedQuote = Quote(
                id: quote.id,
                text: trimmedText,
                page: Int(editedPageText),
                memo: editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      ? nil
                      : editedMemo.trimmingCharacters(in: .whitespacesAndNewlines),
                bookId: quote.bookId
            )
            Task {
                let success = await viewModel.updateQuote(updatedQuote)
                if success { dismiss() }
        }
    }
}

