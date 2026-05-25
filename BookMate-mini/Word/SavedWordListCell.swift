//
//  SavedWordListCell.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct SavedWordListCell: View {
    let text: String
    let partOfSpeech: String
    let meaning: String
    let title: String

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

            Divider()
            
            HStack {
                Image(systemName: "book")
                Text("\(title)")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color("GreenHeavy"))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color("GreenLight"))
            .clipShape(Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
        )
        .padding(.horizontal, 28)
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
    }
}

#Preview {
    SavedWordListCell(
        text: Word.sampleWords[0].text,
        partOfSpeech: Word.sampleWords[0].partOfSpeech,
        meaning: Word.sampleWords[0].meaning,
        title: Book.dummyBooks[0].title
    )
}
