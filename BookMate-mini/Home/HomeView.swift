//
//  HomeView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: BookMateViewModel // 다른 곳에서 만든 viewModel 받아서 관찰
    @Binding var selectedTab: Int
    @State private var path = NavigationPath()
    @State private var selectedBookToDelete: Book?
    @State private var isShowingDeleteAlert = false

    private struct BookEditTarget: Identifiable {
        let id: UUID
    }
    
    @State private var selectedBookToEdit: BookEditTarget?
    
    private enum HomeRoute: Hashable {
        case bookSearch
        case bookDetail(UUID)
    }

    var body: some View {
        NavigationStack(path: $path){
            
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
                                ForEach(viewModel.savedWords.prefix(5)) { word in
                                    NavigationLink {
                                        WordDetailsView(viewModel: viewModel, word: word)
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
                            NavigationLink(value: HomeRoute.bookDetail(book.id)) {
                                BookCardView(
                                    imageName: book.imageName,
                                    title: book.title,
                                    author: book.author,
                                    progress: book.progress,
                                    onEdit: {
                                            selectedBookToEdit = BookEditTarget(id: book.id)
                                        },
                                        onDelete: {
                                            selectedBookToDelete = book
                                            isShowingDeleteAlert = true
                                        }
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        
                        HStack {
                            Spacer()
                            
                            NavigationLink(value: HomeRoute.bookSearch) {
                                //                                BookSearchView(viewModel: viewModel, selectedTab: $selectedTab)
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundStyle(Color("Peach"))
                                    .shadow(color: Color("Peach").opacity(0.08), radius: 14, x: 0, y: 8)
                                    .padding()
                            } // 이 버튼을 누르면 path에 HomeRoute.bookSearch 라는 값을 넣어줘.
                            // 그 값을 받으면 어디로 갈지는 아래에서 정함
                            .padding(.trailing, 24)
                            
                        }
                        
                    }
                    .buttonStyle(.plain)
                    
                }
                
            }
            .sheet(item: $selectedBookToEdit) { target in
                if let book = viewModel.books.first(where: {$0.id == target.id }) {
                    BookEditSheet(book: book) { updatedBook in
                        await viewModel.updateBook(updatedBook)
                    }
                    .presentationDetents([.height(420)])
                    .presentationDragIndicator(.visible)
                } else {
                    Text("책 정보를 찾을 수 없습니다.")
                }
            }
            .alert("책을 삭제할까요?", isPresented: $isShowingDeleteAlert) {
                Button("취소", role: .cancel) { }
                
                Button("삭제", role: .destructive) {
                    guard let selectedBookToDelete else { return }
                    
                    Task {
                        let success = await viewModel.deleteBook(selectedBookToDelete)
                        
                        if success {
                            self.selectedBookToDelete = nil
                        }
                    }
                }
            } message: {
                Text("이 책을 삭제하면 저장한 단어도 함께 삭제됩니다.")
            }
            
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .bookSearch:
                    BookSearchView (viewModel: viewModel, selectedTab: $selectedTab,
                                    onFinishRegistration: { tab in
                        selectedTab = tab
                        path = NavigationPath()
                    }
                    )
                case .bookDetail(let bookId):
                        if let book = viewModel.books.first(where: { $0.id == bookId }) {
                            BookDetailView(viewModel: viewModel, book: book)
                        } else {
                            Text("책 정보를 찾을 수 없습니다.")
                        }
                }
            }
        }
        
    }
}

#Preview {
    HomeView(viewModel: BookMateViewModel(), selectedTab: .constant(0))
}
