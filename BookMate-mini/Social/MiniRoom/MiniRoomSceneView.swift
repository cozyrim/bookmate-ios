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
        let onSearchUsers: () -> Void
        let onSurfRandomUser: () -> Void
        let onOpenGuestbook: () -> Void
        let onBookTap: (Book) -> Void
    
    var body: some View {
        ZStack {
                    theme.backgroundColor
                        .ignoresSafeArea()

                    Image(theme.imageName)
                        .resizable()
                        .scaledToFit()
                        .offset(y: -40)

                    VStack(spacing: 0) {
                        MiniRoomHeaderView(
                            nickname: nickname,
                            profileImageUrl: profileImageUrl,
                            showsExploreButtons: showsExploreButtons,
                            isSurfing: isSurfing,
                            onSearchUsers: onSearchUsers,
                            onSurfRandomUser: onSurfRandomUser
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        Spacer()

                        HStack {
                            Spacer()

                            Button(action: onOpenGuestbook) {
                                Label("방명록", systemImage: "text.book.closed.fill")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .foregroundStyle(Color("Primary"))
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 15)
                        }

                        MiniRoomBookshelfView(
                            books: books,
                            onBookTap: onBookTap
                        )
                    }
                }
    }
}

