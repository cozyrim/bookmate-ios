//
//  ShelfView.swift
//  BookMate
//
//  Created by 한채림 on 5/12/26.
//

import SwiftUI

struct ShelfView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color.skyblue
                    .ignoresSafeArea()
                
                VStack(spacing: 20){
                    HStack{
                        Text("내 책장")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        NavigationLink {
                            BookSearchView(viewModel: viewModel, selectedTab: $selectedTab)
                        } label: {
                            Text(" + 새 책 추가")
                                .font(.caption2)
                                .foregroundStyle(Color("Brown"))
                                .fontWeight(.semibold)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(Color("Peach"))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Color("Peach").opacity(0.3), radius: 7, x: 0, y: 2)
                            
                            
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16){
                            ForEach(viewModel.books) { book in
                                NavigationLink {
                                    BookDetailView(viewModel: viewModel, book: book)
                                } label: {
                                    ShelfBookCardView(imageName: book.imageName, author: book.author, title: book.title)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 110)
                    }
                }
            }
        }
    }
}


#Preview {
    ShelfView(viewModel: BookMateViewModel(), selectedTab: .constant(0))
}
