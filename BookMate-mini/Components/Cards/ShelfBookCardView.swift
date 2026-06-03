//
//  ShelfBookCardView.swift
//  BookMate
//
//  Created by 한채림 on 5/12/26.
//

import SwiftUI

struct ShelfBookCardView: View {
    let imageName: String
    let author: String
    let title: String
    let category: String
    let progress: Double
    
    let onTap: () -> Void
    let onMoreTap: () -> Void
    
    private var authorLine: String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCategory.isEmpty || trimmedCategory == "카테고리 선택" {
            return author
        }

        return "\(author) · \(trimmedCategory)"
    }
    
    
    var body: some View {
        HStack {
            BookCoverCell(imageName: imageName, width: 82)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack{
                    Text("\(title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                        Text("12 단어")
                            .font(.caption2)
                            .foregroundStyle(Color("Brown"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color("Green"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
                        
                        Button {
                            onMoreTap()
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black.opacity(0.55))
                                .frame(width: 22, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                }
                Text(authorLine)
                    .font(.caption2)
                    .foregroundStyle(Color("Brown"))
                
                VStack(alignment: .leading){
                    HStack{
                        Text("Gorgeous")
                            .font(.caption2)
                            .foregroundStyle(Color("GreenHeavy"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color("GreenLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("Extravagant")
                            .font(.caption2)
                            .foregroundStyle(Color("GreenHeavy"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color("GreenLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    VStack(spacing: 4) {
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
                .padding(.top)
            }
            

    }
        .padding(.horizontal)
        .frame(width: 350, height: 160)
//        .background(Color.white)
        .background(Color.skyblue)
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }

    }

}

#Preview {
    ShelfBookCardView(imageName: Book.dummyBooks[0].imageName, author:Book.dummyBooks[0].author , title: Book.dummyBooks[0].title, category: "소설", progress: 0.65, onTap: {},
                      onMoreTap: {})
}
