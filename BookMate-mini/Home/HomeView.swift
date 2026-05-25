//
//  HomeView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            
                ZStack{
                    Image("자연4")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    Color.white.opacity(0.15)
//                    Color.skyblue
                        .ignoresSafeArea()
                    
                    ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        HomeSearchSection(viewModel: viewModel)
                        
                        VStack(alignment: .leading, spacing: 18){
                            HStack {
                                Text("최근 저장한 단어")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal)
                                
                                Spacer()
                                
                                Text("모두 보기")
                                    .foregroundStyle(Color("Brown"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 30)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.savedWords.reversed().prefix(5)) { word in
                                    NavigationLink {
                                        WordDetails(word: word)
                                    } label: {
                                        WordCardView(word: word)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        HStack {
                            Text("내 책장")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                            
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        ForEach(viewModel.books) { book in
                            NavigationLink {
                                BookDetailView(viewModel: viewModel, book: book)
                            } label: {
                                BookCardView(
                                    imageName: book.imageName,
                                    title: book.title,
                                    author: book.author,
                                    progress: book.progress)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            
                            NavigationLink {
                                BookSearchView(viewModel: viewModel, selectedTab: $selectedTab)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundStyle(Color("Peach"))
                                    .shadow(color: Color("Peach").opacity(0.08), radius: 14, x: 0, y: 8)
                                    .padding()
                                
                            }
                        }
                        .padding(.trailing, 24)
                        
                    }
                    
                }
                    .buttonStyle(.plain)
            }
        }
    }

}

#Preview {
    HomeView(viewModel: BookMateViewModel(), selectedTab: .constant(0))
}
