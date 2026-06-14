//
//  MiniRoomHeaderView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomHeaderView: View {
    let nickname: String
    let profileImageUrl: String?
    let showsExploreButtons: Bool
    let isSurfing: Bool
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(
                imageName: "profileImage",
                imageURLString: profileImageUrl,
                showsEditIcon: false,
                size: 50
            )

            Text("\(nickname)님의 책장")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            if showsExploreButtons {
                headerButton(title: "검색", systemImage: "magnifyingglass", action: onSearchUsers)

                Button(action: onSurfRandomUser) {
                    VStack(spacing: 3) {
                        if isSurfing {
                            ProgressView()
                                .tint(Color("Primary"))
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "water.waves")
                                .font(.headline)
                        }

                        Text("파도타기")
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color("PrimaryDeep"))
                    .frame(width: 64, height: 52)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .disabled(isSurfing)
            }
        }
    }

    private func headerButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.headline)

                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color("PrimaryDeep"))
            .frame(width: 52, height: 52)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
