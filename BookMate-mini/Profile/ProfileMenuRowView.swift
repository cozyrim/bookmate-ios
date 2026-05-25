//
//  ProfileMenuRowView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileMenuRowView: View {
        let imageName: String
        let title: String
        var showsChevron: Bool = true
        var isDestructive: Bool = false
    
    private var tintColor: Color {
        isDestructive ? .red : Color("Brown")
    }

            var body: some View {
                HStack(spacing: 14) {
                    Image(systemName: imageName)
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(Color("Brown"))
                        .frame(width: 22, height: 22)

                    Text(title)
                        .font(.callout)
                        .foregroundStyle(isDestructive ? .red : .black)

                    Spacer()

                    if showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color("Brown").opacity(0.8))
                    }
                }
                .frame(height: 42)
    }
}

#Preview {
    ProfileMenuRowView(imageName: "person.crop.circle", title: "내 계정")
}
