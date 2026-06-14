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
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Spacer()

                    if showsExploreButtons {
                        Button(action: onSearchUsers) {
                            Image(systemName: "magnifyingglass")
                        }

                        Button(action: onSurfRandomUser) {
                            if isSurfing {
                                ProgressView()
                            } else {
                                Image(systemName: "water.waves")
                            }
                        }
                        .disabled(isSurfing)
                    }
                }
                .buttonStyle(.bordered)
    }
}
