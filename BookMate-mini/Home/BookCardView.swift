//
//  WordCardView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct BookCardView: View {
    let imageName:String
    let title: String
    let author: String
    let progress: Double
    var body: some View {
        HStack {
            BookCoverCell(imageName: imageName, width: 55)
//                .resizable()
//                .frame(width: 55, height: 77)
//                .clipShape(RoundedRectangle(cornerRadius: 18))
//                .padding(.trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text("\(title)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(author)")
                    .font(.caption2)
                    .foregroundStyle(Color("Brown"))
                
                ProgressView(value: progress)
                    .tint(Color("Peach"))
                          
                        HStack {
                        Spacer()
                        Text("\(Int(progress * 100))% 읽음")
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.7))
                    }
                
        }

    }
        .padding(.horizontal)
        .frame(width: 350, height: 100)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
        .padding(.top, 8)
        .padding(.horizontal,  24)
    }
}

#Preview {
    BookCardView(imageName: "싯타르타", title: "싯타르타", author: "해르만헤세 / 고전소설", progress: 0.65)
}
