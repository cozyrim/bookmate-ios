//
//  ProfileCardCellView.swift
//  BookMate
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileMenuCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let rows: [ProfileMenuItem]
    var onTap: (ProfileMenuItem) -> Void = { _ in }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
            ? [
                Color("SurfaceElevated").opacity(0.94),
                Color("SurfaceElevated").opacity(0.84)
            ]
            : [
                Color.white.opacity(0.98),
                Color(red: 0.985, green: 0.982, blue: 0.965).opacity(0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.white.opacity(0.92)
    }

    private var dividerColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color(red: 0.86, green: 0.86, blue: 0.82).opacity(0.45)
    }

    private var cardShadowColor: Color {
        colorScheme == .dark
        ? Color.black.opacity(0.22)
        : Color(red: 0.62, green: 0.60, blue: 0.55).opacity(0.16)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                Button {
                    onTap(row)
                } label: { ProfileMenuRowView(item: row)
                    }
                .buttonStyle(.plain)
                
                if row.id != rows.last?.id {
                    Rectangle()
                        .fill(dividerColor)
                        .frame(height: 1)
                        .padding(.leading, 36)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        /*
         이전 디자인 백업
         .background(Color("Surface"))
         .clipShape(RoundedRectangle(cornerRadius: 20))
         .shadow(color: Color("Shadow").opacity(0.04), radius: 8, x: 0, y: 4)
         */
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(cardGradient)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        }
        .shadow(color: cardShadowColor, radius: colorScheme == .dark ? 14 : 20, x: 0, y: 10)
        
    }
}

#Preview {
    ProfileMenuCardView(rows: [ProfileMenuItem(imageName: "person.crop.circle", title: "내 계정"),
                               ProfileMenuItem(imageName: "person.badge.plus", title: "프로필 수정"),
                               ProfileMenuItem(imageName: "bell", title: "알림 설정")])
}
