//
//  MiniRoomHeaderView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let controlSize: CGFloat = 44

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
            .frame(height: controlSize)
            .padding(.bottom, 10)
    }

    private var identityRow: some View {
        HStack(alignment: .center, spacing: 10) {
            actionSlot(systemName: "chevron.left", action: onBack)

            ProfileImageView(
                imageName: "profileImage",
                imageURLString: profileImageUrl,
                showsEditIcon: false,
                size: 44
            )

            nicknameChip
                .layoutPriority(2)

            Spacer(minLength: 8)

            actionSlot(systemName: "ellipsis", action: onMoreActions)
        }
    }

    private var nicknameChip: some View {
        Text("\(nickname)님의 책장")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("TextPrimary").opacity(0.92))
            .lineLimit(1)
            .minimumScaleFactor(0.76)
            .truncationMode(.tail)
            .allowsTightening(true)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(chipBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(chipBorder, lineWidth: 1)
            }
    }

    @ViewBuilder
    private func actionSlot(systemName: String, action: (() -> Void)?) -> some View {
        if let action {
            CircleIconButton(systemName: systemName) {
                action()
            }
        } else {
            Color.clear
                .frame(width: controlSize, height: controlSize)
        }
    }
}
