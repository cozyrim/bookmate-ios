//
//  QuoteAddSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import SwiftUI

struct QuoteAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BookMateViewModel
    let bookId: UUID
    
    @State private var text: String = ""
    @State private var pageText: String = ""
    @State private var memo: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("구절").font(.subheadline).fontWeight(.semibold).foregroundStyle(Color("TextMuted"))
                            TextEditor(text: $text)
                                .scrollContentBackground(.hidden).padding(16).frame(minHeight: 140)
                                .background(Color("Surface")).clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("TextMuted").opacity(0.2), lineWidth: 1))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("페이지").font(.subheadline).fontWeight(.semibold).foregroundStyle(Color("TextMuted"))
                            TextField("예) 42", text: $pageText).keyboardType(.numberPad).padding(16)
                                .background(Color("Surface")).clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("TextMuted").opacity(0.2), lineWidth: 1))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("메모 (선택)").font(.subheadline).fontWeight(.semibold).foregroundStyle(Color("TextMuted"))
                            TextEditor(text: $memo)
                                .scrollContentBackground(.hidden).padding(16).frame(minHeight: 100)
                                .background(Color("Surface")).clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("TextMuted").opacity(0.2), lineWidth: 1))
                        }
                        Button {
                            saveQuote()
                        } label: {
                            Text("저장하기").font(.headline).foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color("TextSecondary") : Color("PrimaryButtonText")).frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color("TextMuted").opacity(0.4) : Color("Primary"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("새 구절 추가").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } } }
        }
    }
    private func saveQuote() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let pageInt = Int(pageText)
        let finalMemo = memo.isEmpty ? nil : memo
        
        Task {
            let success = await viewModel.saveQuote(
                            bookId: bookId,
                            text: trimmedText,
                            page: pageInt,
                            memo: finalMemo
                        )
            if success { dismiss() }
        }
    }
}


#Preview {
    QuoteAddSheet(viewModel: BookMateViewModel(), bookId: UUID())
}
