//
//  BookSavedWordCell.swift
//  BookMate
//
//  Created by 한채림 on 5/14/26.
//

import SwiftUI

struct BookSavedWordCell: View {
    let text: String
    let partOfSpeech: String
    let meaning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text("\(text)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(partOfSpeech)")
                    .font(.caption2)
                    .foregroundStyle(Color("Brown"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("\(meaning)")
                .font(.body)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
        )
        .padding(.horizontal, 28)
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
    }
}

#Preview {
    BookSavedWordCell(
        text: Word.sampleWords[0].text,
        partOfSpeech: Word.sampleWords[0].partOfSpeech,
        meaning: "저속한 작품. 또는 공예품. 본래는 예술 가치가 없는 것을 뜻하나, 현대에 와서는 대중문화의 한 속성으로..."
    )
}
