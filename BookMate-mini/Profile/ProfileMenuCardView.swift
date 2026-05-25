//
//  ProfileCardCellView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileMenuCardView: View {
    let rows: [ProfileMenuItem]
    
    var body: some View {
        VStack{
            ForEach(rows) { row in
                ProfileMenuRowView(imageName: row.imageName, title: row.title, showsChevron: row.showChevron, isDestructive: row.isDestructive)
            
                if row.id != rows.last?.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        
    }
}

#Preview {
    ProfileMenuCardView(rows: [ProfileMenuItem(imageName: "person.crop.circle", title: "내 계정"),
                               ProfileMenuItem(imageName: "person.badge.plus", title: "프로필 수정"),
                               ProfileMenuItem(imageName: "bell", title: "알림 설정")])
}
