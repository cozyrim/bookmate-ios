//
//  MainTabView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    @StateObject private var viewModel = BookMateViewModel() // StateObject는 처음 Viewmodel 만들고 소유
    @State var tabIndex = 0

    var body: some View {
        TabView(selection: $tabIndex) {
            HomeView(viewModel: viewModel, selectedTab: $tabIndex)
                .tabItem {
                    Image(systemName: "house")
                    Text("홈")
                }
                .tag(0)

            ShelfView(viewModel: viewModel, selectedTab: $tabIndex)
                .tabItem {
                    Image(systemName: "book")
                    Text("책장")
                }
                .tag(1)


            WordArchiveView(viewModel: viewModel, selectedTab: $tabIndex)
                .tabItem {
                    Image(systemName: "tag")
                    Text("단어 아카이빙")
                }
                .tag(2)

            RoomTabView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("방 구경")
                }
                .tag(3)


            ProfileView(authViewModel: authViewModel)
                .tabItem{
                    Image(systemName: "person.crop.circle.fill")
                    Text("프로필")
                }
                .tag(4)

        }
        .tint(Color("Primary"))
        .appToast($viewModel.toast) // MainTabView가 가진 viewModel.toast 값을 AppToastModifier에게 연결해서 넘긴다.원본 값을 읽고 바꿀 수 있는 연결 통로 전달
        .task(id: authViewModel.currentUser?.id) {
            viewModel.setRecentSearchOwner(userId: authViewModel.currentUser?.id) // 로그인한 사용자마다 최근 검색어 저장칸이 다름

            await viewModel.loadBooks()
            await viewModel.loadSavedWords()
        }
        .onChange(of: viewModel.didReceiveUnauthorized) { _, expired in
            guard expired else { return }
            authViewModel.logout()
            viewModel.didReceiveUnauthorized = false
        } // 401이 오면 자동으로 로그아웃되고 로그인 화면으로 돌아감


    }
}

#Preview {
    MainTabView(authViewModel: AuthSessionViewModel())
}
