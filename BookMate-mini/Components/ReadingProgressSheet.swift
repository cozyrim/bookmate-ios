//
//  ReadingProgressSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI

struct ReadingProgressSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let book: Book
    let onSave: (Int, Int) -> Void
    
    @State private var totalPagesText = ""
    @State private var currentPageText = ""
    
    private var totalPages: Int? {
        Int(totalPagesText)
    }
    
    private var currentPage: Int? {
        Int(currentPageText)
    }
    
    private var calculatedProgress: Double? {
        guard let totalPages,
              let currentPage,
              totalPages > 0,
              currentPage >= 0,
              currentPage <= totalPages else {
            return nil
        }
        
        return Double(currentPage) / Double(totalPages)
    }
    
    private var calculatedPercentText: String {
        guard let calculatedProgress else {
            return "\(Int(book.progress * 100))%"
        }
        
        return "\(Int(calculatedProgress * 100))%"
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.25))
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("읽은 쪽수 업데이트")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(book.title)
                    .font(.callout)
                    .foregroundStyle(Color("Brown"))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("현재 진행률")
                        .font(.callout)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(calculatedPercentText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("PeachRedHeavy"))
                }
                
                ProgressView(value: calculatedProgress ?? book.progress)
                    .tint(Color("Peach"))
            }
            
            VStack(spacing: 14) {
                pageInputField(
                    title: "전체 쪽수",
                    placeholder: "예: 320",
                    text: $totalPagesText
                )
                
                pageInputField(
                    title: "읽은 쪽수",
                    placeholder: "예: 120",
                    text: $currentPageText
                )
            }
            
            if let totalPages,
               let currentPage,
               currentPage > totalPages {
                Text("읽은 쪽수는 전체 쪽수보다 클 수 없어요.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            Button {
                guard let totalPages,
                      let currentPage,
                      totalPages > 0,
                      currentPage <= totalPages else {
                    return
                }
                
                onSave(totalPages, currentPage)
                dismiss()
            } label: {
                Text("저장하기")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(calculatedProgress == nil ? Color.gray.opacity(0.35) : Color("Peach"))
                    .clipShape(Capsule())
            }
            .disabled(calculatedProgress == nil)
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .background(Color.skyblue)
        .onAppear {
            if let totalPages = book.totalPages {
                totalPagesText = String(totalPages)
            }
            
            if let currentPage = book.currentPage {
                currentPageText = String(currentPage)
            }
        }
    }
    private func pageInputField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("Brown"))
            
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

#Preview {
    ReadingProgressSheet(book: Book.dummyBooks[0]) { totalPages, currentPage in
        print("전체 쪽수:", totalPages)
        print("읽은 쪽수:", currentPage)
    }
}
