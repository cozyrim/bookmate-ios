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
    
    let onEdit: () -> Void
    let onDelete: () -> Void
    
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
                        
                        MoreOptionsMenu(
                            editTitle: "책 수정하기",
                            deleteTitle: "책 삭제하기",
                            moveTitle: nil,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )

                }
                Text("\(author)")
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
                    HStack {
                        Text("Evolution")
                            .font(.caption2)
                            .foregroundStyle(Color("GreenHeavy"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color("GreenLight"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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

    }

}

#Preview {
    ShelfBookCardView(imageName: Book.dummyBooks[0].imageName, author:Book.dummyBooks[0].author , title: Book.dummyBooks[0].title, onEdit: {},
                      onDelete: {})
}
