//
//  MiniRoomSceneView.swift
//  BookMate
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomSceneView: View {
    private enum Layout {
        static let headerHorizontalPadding: CGFloat = 20
        static let headerTopSpacing: CGFloat = 84
    }

    let nickname: String
    let profileImageUrl: String?
    let theme: MiniRoomTheme
    let books: [Book]
    let showsExploreButtons: Bool
    let isSurfing: Bool
    let onBack: (() -> Void)?
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void
    let onChangeTheme: (() -> Void)?
    let onMoreActions: (() -> Void)?
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
        onChangeTheme: (() -> Void)? = nil,
        onMoreActions: (() -> Void)? = nil,
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
        self.onChangeTheme = onChangeTheme
        self.onMoreActions = onMoreActions
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
                        onBack: onBack,
                        onMoreActions: onMoreActions
                    )
                    .padding(.horizontal, Layout.headerHorizontalPadding)
                    .padding(.top, Layout.headerTopSpacing)
                    .background(theme.backgroundColor)

                    MiniRoomCanvas(
                        theme: theme,
                        books: books,
                        showsExploreButtons: showsExploreButtons,
                        isSurfing: isSurfing,
                        onSearchUsers: onSearchUsers,
                        onSurfRandomUser: onSurfRandomUser,
                        onChangeTheme: onChangeTheme,
                        onOpenGuestbook: onOpenGuestbook,
                        onBookTap: onBookTap
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.container, edges: .bottom)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .onAppear {
            PerformanceLogger.event("MiniRoomSceneAppear")
        }
    }
}

private struct MiniRoomCanvas: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let theme: MiniRoomTheme
    let books: [Book]
    let showsExploreButtons: Bool
    let isSurfing: Bool
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void
    let onChangeTheme: (() -> Void)?
    let onOpenGuestbook: () -> Void
    let onBookTap: (Book) -> Void

    private let backgroundAspectRatio: CGFloat = 1024 / 1536

    private var controlForeground: Color {
        if theme == .dark {
            return Color(red: 173.0 / 255.0, green: 193.0 / 255.0, blue: 228.0 / 255.0)
        }

        return colorScheme == .dark
            ? Color("TabBarSelected")
            : Color("PrimaryDeep").opacity(0.82)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let availableHeight = max(proxy.size.height, 1)
            let canvasWidth = min(width * 1.20, 520)
            let canvasHeight = canvasWidth / backgroundAspectRatio
            let canvasTop = max(0, availableHeight - canvasHeight)
            let topExtensionOverlap = min(36, max(18, canvasTop * 0.08))
            let guestbookX = min(width - 88, max(88, width / 2 - canvasWidth * 0.25))
            let guestbookY = min(canvasTop + canvasHeight * 0.81, availableHeight - 64)
            let actionButtonsX = min(width - 104, max(178, width / 2 + canvasWidth * 0.20))
            let defaultActionButtonsY = canvasTop + min(max(52, canvasHeight * 0.073), 66)
            let liftedActionButtonsY = max(64, canvasTop - min(62, max(36, canvasTop * 0.12)))
            let actionButtonsY = horizontalSizeClass == .regular && canvasTop > 140
                ? liftedActionButtonsY
                : defaultActionButtonsY

            ZStack(alignment: .top) {
                if canvasTop > 1 {
                    topExtensionImage(
                        theme.topExtensionImageName,
                        canvasWidth: canvasWidth,
                        visibleHeight: canvasTop,
                        overlap: topExtensionOverlap,
                        containerWidth: width
                    )
                }

                layeredImage(
                    theme.sceneImageName(for: colorScheme),
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    canvasTop: canvasTop,
                    containerWidth: width
                )
                .shadow(color: Color("Shadow").opacity(theme == .dark ? 0.06 : 0.12), radius: 18, y: 8)

                MiniRoomBookshelfView(
                    books: books,
                    onBookTap: onBookTap
                )
                .frame(width: canvasWidth, height: canvasHeight)
                .position(x: width / 2, y: canvasTop + canvasHeight / 2)

                if showsExploreButtons {
                    MiniRoomFloatingActions(
                        isSurfing: isSurfing,
                        controlForeground: controlForeground,
                        onSearchUsers: onSearchUsers,
                        onSurfRandomUser: onSurfRandomUser,
                        onChangeTheme: onChangeTheme
                    )
                    .position(x: actionButtonsX, y: actionButtonsY)
                }

                Button {
                    PerformanceLogger.event("MiniRoomCanvasGuestbookButtonTapped")
                    onOpenGuestbook()
                } label: {
                    Label("방명록", systemImage: "heart.text.square")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(controlForeground)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color("Shadow").opacity(0.16), radius: 12, y: 5)
                        )
                }
                .buttonStyle(.plain)
                .position(x: guestbookX, y: max(52, guestbookY))
            }
            .frame(width: width, height: availableHeight, alignment: .top)
            .background(theme.backgroundColor)
        }
    }

    private func topExtensionImage(_ name: String, canvasWidth: CGFloat, visibleHeight: CGFloat, overlap: CGFloat, containerWidth: CGFloat) -> some View {
        let imageHeight = visibleHeight + overlap

        return ZStack {
            Image(name)
                .resizable()

            if theme.sceneTintOpacity > 0 {
                theme.sceneTintColor
                    .opacity(theme.sceneTintOpacity)
                    .blendMode(.softLight)

                theme.sceneTintColor
                    .opacity(theme.sceneTintOpacity * 0.42)
                    .blendMode(.color)
            }
        }
        .compositingGroup()
        .frame(width: canvasWidth, height: imageHeight)
        .clipped()
        .position(x: containerWidth / 2, y: imageHeight / 2)
        .allowsHitTesting(false)
    }

    private func layeredImage(_ name: String, canvasWidth: CGFloat, canvasHeight: CGFloat, canvasTop: CGFloat, containerWidth: CGFloat) -> some View {
        ZStack {
            Image(name)
                .resizable()
                .scaledToFit()

            if theme.sceneTintOpacity > 0 {
                theme.sceneTintColor
                    .opacity(theme.sceneTintOpacity)
                    .blendMode(.softLight)

                theme.sceneTintColor
                    .opacity(theme.sceneTintOpacity * 0.42)
                    .blendMode(.color)
            }
        }
            .compositingGroup()
            .frame(width: canvasWidth, height: canvasHeight)
            .clipped()
            .position(x: containerWidth / 2, y: canvasTop + canvasHeight / 2)
    }
}

private struct MiniRoomFloatingActions: View {
    let isSurfing: Bool
    let controlForeground: Color
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void
    let onChangeTheme: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            if let onChangeTheme {
                actionButton(title: "배경", systemImage: "paintpalette", action: onChangeTheme)
                divider
            }

            actionButton(title: "검색", systemImage: "magnifyingglass", action: onSearchUsers)
            divider

            Button(action: onSurfRandomUser) {
                VStack(spacing: 2) {
                    if isSurfing {
                        ProgressView()
                            .tint(controlForeground)
                            .frame(width: 17, height: 17)
                    } else {
                        Image(systemName: "water.waves")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text("파도타기")
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(controlForeground)
                .frame(width: 52, height: 40)
            }
            .buttonStyle(.plain)
            .disabled(isSurfing)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color("Shadow").opacity(0.14), radius: 10, y: 4)
        )
        .overlay {
            Capsule()
                .stroke(Color("Surface").opacity(0.36), lineWidth: 1)
        }
        .fixedSize()
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))

                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(controlForeground)
            .frame(width: 42, height: 40)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(controlForeground.opacity(0.15))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 2)
    }
}
