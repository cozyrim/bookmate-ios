//
//  MainTabView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = BookMateViewModel()
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
            
            
            WordArchiveView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "tag")
                    Text("단어 아카이빙")
                }
                .tag(2)
            
            ProfileView()
                .tabItem{
                    Image(systemName: "person.crop.circle.fill")
                    Text("프로필")
                }
                .tag(3)
            
        }
        .tint(Color("PeachRed"))
        .task {
            await viewModel.loadSavedWords()
        }
    }
}

#Preview {
    MainTabView()
}
