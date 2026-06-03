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
    let category: String
    
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
            BookCoverCell(imageName: imageName, width: 55)
//                .resizable()
//                .frame(width: 55, height: 77)
//                .clipShape(RoundedRectangle(cornerRadius: 18))
//                .padding(.trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                
                HStack{
                    Text("\(title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
//                    MoreOptionsMenu(
//                                            editTitle: "책 수정하기",
//                                            deleteTitle: "책 삭제하기",
//                                            moveTitle: nil,
//                                            onEdit:onEdit,
//                                            onDelete: onDelete
//                                            )
                    
                    Button {
                        onMoreTap()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color("TextPrimary").opacity(0.55))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                       
                }
                
                Text(authorLine)
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary"))
                
                ProgressView(value: progress)
                    .tint(Color("Primary"))
                          
                        HStack {
                        Spacer()
                        Text("\(Int(progress * 100))% 읽음")
                            .font(.caption)
                            .foregroundStyle(Color("TextPrimary").opacity(0.7))
                    }
                
        }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
        .padding(.horizontal)
        .frame(width: 350, height: 100)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
        .padding(.top, 8)
        .padding(.horizontal,  24)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    BookCardView(imageName: "싯타르타", title: "싯타르타", author: "해르만헤세 / 고전소설", progress: 0.65, category: "소설", onTap: {},
                 onMoreTap: {})
}
