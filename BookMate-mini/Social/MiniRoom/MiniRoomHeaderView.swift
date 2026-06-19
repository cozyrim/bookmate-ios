//
//  MiniRoomHeaderView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let nickname: String
    let profileImageUrl: String?
    let onBack: (() -> Void)?
    let onMoreActions: (() -> Void)?

    init(
        nickname: String,
        profileImageUrl: String?,
        onBack: (() -> Void)? = nil,
        onMoreActions: (() -> Void)? = nil
    ) {
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.onBack = onBack
        self.onMoreActions = onMoreActions
    }

    private var chipBackground: Color {
        colorScheme == .dark
        ? Color("SurfaceElevated").opacity(0.74)
        : Color.white.opacity(0.78)
    }

    private var chipBorder: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color("Border").opacity(0.3)
    }

    var body: some View {
        identityRow
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private var identityRow: some View {
        HStack(spacing: 10) {
            if let onBack {
                CircleIconButton(systemName: "chevron.left") {
                    onBack()
                }
            }

            ProfileImageView(
                imageName: "profileImage",
                imageURLString: profileImageUrl,
                showsEditIcon: false,
                size: 44
            )

            Text("\(nickname)님의 책장")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("TextPrimary").opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .allowsTightening(true)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(chipBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(chipBorder, lineWidth: 1)
                }
                .layoutPriority(2)

            if let onMoreActions {
                CircleIconButton(systemName: "ellipsis") {
                    onMoreActions()
                }
            }
        }
    }
}
