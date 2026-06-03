//
//  ProfileMenuRowView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileMenuRowView: View {
//        let imageName: String
//        let title: String
//        var showsChevron: Bool = true
//        var isDestructive: Bool = false
    let item: ProfileMenuItem
    
    private var tintColor: Color {
        item.isDestructive ? .red : Color("Brown")
    }

            var body: some View {
                HStack(spacing: 14) {
                    Image(systemName: item.imageName)
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(Color("Brown"))
                        .frame(width: 22, height: 22)

                    Text(item.title)
                        .font(.callout)
                        .foregroundStyle(item.isDestructive ? .red : .black)

                    Spacer()

                    if item.showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color("Brown").opacity(0.8))
                    }
                }
                .frame(height: 42)
    }
}

#Preview {
    ProfileMenuRowView(
            item: ProfileMenuItem(
                imageName: "person.crop.circle",
                title: "프로필 수정"
            )
        )
}
