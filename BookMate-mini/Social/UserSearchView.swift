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
    @State private var blockedUserIDs: Set<UUID> = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    
    let onSelectUser: ((PublicUserResponse) -> Void)?

    private let socialService = SocialAPIService()
    private let moderationService = ModerationAPIService()
    private let tokenStore = KeychainTokenStore()

    init(onSelectUser: ((PublicUserResponse) -> Void)? = nil) {
        self.onSelectUser = onSelectUser
    }

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack {
                if searchResults.isEmpty {
                    ContentUnavailableView(
                        "닉네임으로 검색하기",
                        systemImage: "magnifyingglass",
                        description: Text("다른 유저의 닉네임을 검색해 책장을 구경해 보세요.")
                    )
                } else {
                    List(searchResults) { user in
                        Button {
                            onSelectUser?(user)
                        } label: {
                            HStack(spacing: 12) {
                                ProfileImageView(
                                    imageName: "profileImage",
                                    imageURLString: user.profileImageUrl,
                                    showsEditIcon: false,
                                    size: 40
                                )
                                
                                Text(user.nickname)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color("TextMuted"))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("유저 검색")
        .searchable(text: $searchText, prompt: "닉네임을 검색하세요")
        .onChange(of: searchText) { _, newValue in
            scheduleSearch(for: newValue)
        }
        .onDisappear {
            searchTask?.cancel()
        }
        //            Task {
        //                await performSearch()
        //            }
        //        }
        //        .task {
        //            await loadBlockedUsers()
        //        }
    }

    @MainActor
    private func scheduleSearch(for rawText: String) {
        searchTask?.cancel()
        
        let query = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard query.count >= 1 else {
                searchResults = []
                isSearching = false
                return
            }
        
        searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }

                await performSearch(query: query)
            }
    }
    
    @MainActor
    private func performSearch(query: String) async {
        guard let token = tokenStore.load() else { return }

            isSearching = true
            defer { isSearching = false }

        do {
            let users = try await socialService.searchUsers(token: token, nickname: query)
            
            guard query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else {
                        return
                    }
            
            searchResults = users.filter { !blockedUserIDs.contains($0.id) }
        } catch {
            if !Task.isCancelled {
                        print("유저 검색 실패:", error)
                    }
        }
    }

    private func loadBlockedUsers() async {
        do {
            let blocks = try await moderationService.fetchBlockedUsers()
            blockedUserIDs = Set(blocks.map(\.blockedUserId))
        } catch {
            print("차단 목록 로드 실패:", error)
        }
    }
}

#Preview {
    UserSearchView()
}
