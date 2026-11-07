//
//  ProfileMenuRowView.swift
//  BookMate
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileMenuRowView: View {
    @ScaledMetric(relativeTo: .body) private var iconColumnWidth: CGFloat = 24
//        let imageName: String
//        let title: String
//        var showsChevron: Bool = true
//        var isDestructive: Bool = false
    let item: ProfileMenuItem
    
    private var tintColor: Color {
        item.isDestructive ? Color("Error") : Color("TextSecondary")
    }

            var body: some View {
                HStack(spacing: 12) {
                    Image(systemName: item.imageName)
                        .font(.body)
                        .foregroundStyle(tintColor)
                        .frame(width: iconColumnWidth)

                    Text(item.title)
                        .font(.callout)
                        .foregroundStyle(item.isDestructive ? Color("Error") : Color("TextPrimary"))

                    Spacer()

                    if item.showChevron {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
                .padding(.vertical, 8)
                .frame(minHeight: 44)
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
