//
//  BookSearchResultRow.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI

// 검색 결과에서 책 하나를 보여주는 셀/row
struct BookSearchResultRow: View {
    let imageName:String
    let title: String
    let author: String
    var body: some View {
        HStack {
            BookCoverCell(imageName: imageName, width: 44)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text("\(title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(author)")
                        .font(.caption2)
                        .foregroundStyle(Color("TextSecondary"))
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color("Primary"))
            }
    }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 86)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color("Shadow").opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    BookSearchResultRow(imageName: "싯타르타", title: "싯타르타", author: "해르만헤세 / 고전소설")
}
