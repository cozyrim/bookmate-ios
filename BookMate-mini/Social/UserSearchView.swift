//
//  UserSearchView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/10/26.
//

import SwiftUI

struct UserSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [PublicUserResponse] = []
        
    private let socialService = SocialAPIService()
    private let tokenStore = KeychainTokenStore()
        
    var body: some View {
        NavigationStack {
                    ZStack {
                        Color("AppBackground").ignoresSafeArea()
                        
                        VStack {
                            if searchResults.isEmpty {
                                ContentUnavailableView("닉네임으로 검색하기", systemImage: "magnifyingglass", description: Text("다른 유저의 닉네임을 검색해 책장을 구경해 보세요."))
                            } else {
                                List(searchResults) { user in
                                    NavigationLink(destination: PublicBookshelfView(targetUser: user)) {
                                        HStack(spacing: 12) {
                                            ProfileImageView(
                                                imageName: "profileImage",
                                                imageURLString: user.profileImageUrl,
                                                selectedImage: nil,
                                                showsEditIcon: false
                                            )
                                            .frame(width: 40, height: 40)
                                            
                                            Text(user.nickname)
                                                .font(.body)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                .listStyle(.plain)
                            }
                        }
                    }
                    .navigationTitle("유저 검색")
                    .searchable(text: $searchText, prompt: "닉네임을 검색하세요")
                    .onSubmit(of: .search) {
                        Task {
                            await performSearch()
                        }
                    }
                }
            }
            
            private func performSearch() async {
                guard let token = tokenStore.load(), !searchText.isEmpty else { return }
                do {
                    searchResults = try await socialService.searchUsers(token: token, nickname: searchText)
                } catch {
                    print("유저 검색 실패:", error)
                }
            }
        }

#Preview {
    UserSearchView()
}
