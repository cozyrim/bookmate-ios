//
//  BookCardView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct WordCardView: View {
//    let text: String
//    let meaning: String
    let word: Word
    let isFeatured: Bool
//    
//    let onEdit: () -> Void
//    let onDelete: () -> Void
//    let onMove: () -> Void

    init(word: Word, isFeatured: Bool = false) {
        self.word = word
        self.isFeatured = isFeatured
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isFeatured ? 10 : 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.text)
                    .font(isFeatured ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary").opacity(0.9))

                if !word.partOfSpeech.isEmpty {
                    PartOfSpeechBadge(text: word.partOfSpeech)
                }

                Spacer(minLength: 0)
                
//                MoreOptionsMenu(
//                    onEdit: onEdit,
//                    onDelete: onDelete,
//                    onMove: onMove
//                )
                
                
            }
            //            .padding()
            Text(word.meaning)
                .font(isFeatured ? .callout : .caption)
                .foregroundStyle(Color("TextSecondary"))
                .fontWeight(isFeatured ? .regular : .medium)
                .lineSpacing(isFeatured ? 3 : 2)
                .lineLimit(isFeatured ? 3 : 2)
        }
        .padding(.horizontal, isFeatured ? 18 : 18)
        .padding(.vertical, isFeatured ? 16 : 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isFeatured ? 110 : 82, alignment: .topLeading)
        .background(Color("Surface").opacity(isFeatured ? 0.96 : 0.88))
        .clipShape(RoundedRectangle(cornerRadius: isFeatured ? 28 : 24, style: .continuous))
        .overlay(alignment: .leading) {
            if isFeatured {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("Primary").opacity(0.74))
                    .frame(width: 4)
                    .padding(.vertical, 20)
            }
        }
        .shadow(color: Color("Shadow").opacity(isFeatured ? 0.055 : 0.035), radius: isFeatured ? 12 : 8, x: 0, y: 4)
    }
}

#Preview {
//    WordCardView(text: Word.sampleWords[1].text, meaning: Word.sampleWords[1].meaning, word: <#Word#>)
    WordCardView(word: Word.sampleWords[0])
}
