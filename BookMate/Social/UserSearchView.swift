//
//  UserSearchView.swift
//  BookMate
//
//  Created by 한채림 on 6/10/26.
//

import SwiftUI

struct UserSearchView: View {
    
    let onSelectUser: ((PublicUserResponse) -> Void)?


    @StateObject private var model: UserSearchViewModel

    init(dependencies: AppDependencies? = nil, onSelectUser: ((PublicUserResponse) -> Void)? = nil) {
        self.onSelectUser = onSelectUser
        _model = StateObject(wrappedValue: UserSearchViewModel(dependencies: dependencies ?? AppDependencies()))
    }

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack {
                if model.searchResults.isEmpty {
                    ContentUnavailableView(
                        "닉네임으로 검색하기",
                        systemImage: "magnifyingglass",
                        description: Text("다른 유저의 닉네임을 검색해 책장을 구경해 보세요.")
                    )
                } else {
                    List(model.searchResults) { user in
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
        .searchable(text: $model.searchText, prompt: "닉네임을 검색하세요")
        .onChange(of: model.searchText) { _, newValue in
            model.scheduleSearch(for: newValue)
        }
        .onDisappear {
            model.cancelSearch()
        }
        //            Task {
        //                await performSearch()
        //            }
        //        }
        //        .task {
        //            await loadBlockedUsers()
        //        }
    }


}

#Preview {
    UserSearchView()
}
