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
        VStack(spacing: 0) {
            ForEach(rows) { row in
                ProfileMenuRowView(imageName: row.imageName, title: row.title, showsChevron: row.showChevron, isDestructive: row.isDestructive)

                /*
                 이전 디자인 백업
                 if row.id != rows.last?.id {
                     Divider()
                         .padding(.leading, 36)
                 }
                 */
                if row.id != rows.last?.id {
                    Rectangle()
                        .fill(Color.white.opacity(0.38))
                        .frame(height: 1)
                        .padding(.leading, 36)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        /*
         이전 디자인 백업
         .background(Color.white)
         .clipShape(RoundedRectangle(cornerRadius: 20))
         .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
         */
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.38),
                                    Color(red: 0.92, green: 0.98, blue: 1.0).opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 8)
        
    }
}

#Preview {
    ProfileMenuCardView(rows: [ProfileMenuItem(imageName: "person.crop.circle", title: "내 계정"),
                               ProfileMenuItem(imageName: "person.badge.plus", title: "프로필 수정"),
                               ProfileMenuItem(imageName: "bell", title: "알림 설정")])
}
