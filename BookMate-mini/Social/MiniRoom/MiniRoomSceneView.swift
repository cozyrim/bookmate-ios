//
//  MiniRoomSceneView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomSceneView: View {
    let nickname: String
    let profileImageUrl: String?
    let theme: MiniRoomTheme
    let books: [Book]
    let showsExploreButtons: Bool
    let isSurfing: Bool
    let onBack: (() -> Void)?
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void
    let onOpenGuestbook: () -> Void
    let onBookTap: (Book) -> Void

    init(
        nickname: String,
        profileImageUrl: String?,
        theme: MiniRoomTheme,
        books: [Book],
        showsExploreButtons: Bool,
        isSurfing: Bool,
        onBack: (() -> Void)? = nil,
        onSearchUsers: @escaping () -> Void,
        onSurfRandomUser: @escaping () -> Void,
        onOpenGuestbook: @escaping () -> Void,
        onBookTap: @escaping (Book) -> Void
    ) {
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.theme = theme
        self.books = books
        self.showsExploreButtons = showsExploreButtons
        self.isSurfing = isSurfing
        self.onBack = onBack
        self.onSearchUsers = onSearchUsers
        self.onSurfRandomUser = onSurfRandomUser
        self.onOpenGuestbook = onOpenGuestbook
        self.onBookTap = onBookTap
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    MiniRoomHeaderView(
                        nickname: nickname,
                        profileImageUrl: profileImageUrl,
                        showsExploreButtons: showsExploreButtons,
                        isSurfing: isSurfing,
                        onBack: onBack,
                        onSearchUsers: onSearchUsers,
                        onSurfRandomUser: onSurfRandomUser
                    )
                    .padding(.leading, onBack == nil ? 24 : 12)
                    .padding(.trailing, 24)
                    .padding(.top, 20)

                    MiniRoomCanvas(
                        books: books,
                        onOpenGuestbook: onOpenGuestbook,
                        onBookTap: onBookTap
                    )
                    .frame(height: max(560, proxy.size.height - 118))
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            PerformanceLogger.event("MiniRoomSceneAppear")
        }
    }
}

private struct MiniRoomCanvas: View {
    let books: [Book]
    let onOpenGuestbook: () -> Void
    let onBookTap: (Book) -> Void

    private let backgroundAspectRatio: CGFloat = 1024 / 1536

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let canvasWidth = min(width * 1.2, 520)
            let canvasHeight = canvasWidth / backgroundAspectRatio
            let guestbookX = min(width - 88, max(88, width / 2 - canvasWidth * 0.25))

            ZStack(alignment: .top) {
                layeredImage("MiniRoomLayeredRoomBackground", canvasWidth: canvasWidth, canvasHeight: canvasHeight, containerWidth: width)
                    .shadow(color: Color("Shadow").opacity(0.12), radius: 18, y: 8)

                MiniRoomBookshelfView(
                    books: books,
                    onBookTap: onBookTap
                )
                .frame(width: canvasWidth, height: canvasHeight)
                .position(x: width / 2, y: canvasHeight / 2)

                Button {
                    PerformanceLogger.event("MiniRoomCanvasGuestbookButtonTapped")
                    onOpenGuestbook()
                } label: {
                    Label("방명록", systemImage: "heart.text.square")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color("PrimaryDeep"))
                        .padding(.horizontal, 17)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color("Shadow").opacity(0.16), radius: 12, y: 5)
                        )
                }
                .buttonStyle(.plain)
                .position(x: guestbookX, y: canvasHeight * 0.81)
            }
            .frame(width: width, height: proxy.size.height, alignment: .top)
            .offset(y: -4)
        }
    }

    private func layeredImage(_ name: String, canvasWidth: CGFloat, canvasHeight: CGFloat, containerWidth: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: canvasWidth, height: canvasHeight)
            .position(x: containerWidth / 2, y: canvasHeight / 2)
    }
}
