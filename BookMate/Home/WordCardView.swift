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
//    
//    let onEdit: () -> Void
//    let onDelete: () -> Void
//    let onMove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(word.text)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextPrimary"))
                Spacer()
                Text("저장됨")
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color("SuccessSoft"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
//                MoreOptionsMenu(
//                    onEdit: onEdit,
//                    onDelete: onDelete,
//                    onMove: onMove
//                )
                
                
            }
            //            .padding()
            Text("\(word.meaning)")
            
                .font(.caption)
                .foregroundStyle(Color("TextSecondary"))
                .fontWeight(.medium)
                .lineLimit(2)
        }
        .padding(18)
        .frame(width: 265, height: 90)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
        
    }
}

#Preview {
//    WordCardView(text: Word.sampleWords[1].text, meaning: Word.sampleWords[1].meaning, word: <#Word#>)
    WordCardView(word: Word.sampleWords[0])
}
