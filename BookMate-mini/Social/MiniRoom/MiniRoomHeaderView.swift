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
    let showsExploreButtons: Bool
    let isSurfing: Bool
    let onBack: (() -> Void)?
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void

    init(
        nickname: String,
        profileImageUrl: String?,
        showsExploreButtons: Bool,
        isSurfing: Bool,
        onBack: (() -> Void)? = nil,
        onSearchUsers: @escaping () -> Void,
        onSurfRandomUser: @escaping () -> Void
    ) {
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.showsExploreButtons = showsExploreButtons
        self.isSurfing = isSurfing
        self.onBack = onBack
        self.onSearchUsers = onSearchUsers
        self.onSurfRandomUser = onSurfRandomUser
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

            Spacer(minLength: 4)

            if showsExploreButtons {
                HStack(spacing: 6) {
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
                        .frame(width: 58, height: 48)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSurfing)
                }
                .fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
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
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
