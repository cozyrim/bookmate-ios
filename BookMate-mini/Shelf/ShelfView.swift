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
    
    @State private var path = NavigationPath()
    @State private var selectedBookToDelete: Book?
    @State private var isShowingDeleteAlert = false
    
    
    private struct BookEditTarget: Identifiable {
        let id: UUID
    }

    @State private var selectedBookToEdit: BookEditTarget?
    
    private enum ShelfRoute: Hashable {
        case bookSearch
        case bookDetail(UUID)
    } // 책장 화면에서 이동할 수 있는 목적지 목록
//    버튼 클릭
//    ↓
//    path에 ShelfRoute.bookSearch 저장
//    ↓
//    NavigationStack이 path 변화를 감지
//    ↓
//    .navigationDestination이 그 값을 보고 실제 화면을 띄움


    var body: some View {
        NavigationStack(path: $path){
            ZStack{
                Color.skyblue
                    .ignoresSafeArea()
                
                VStack(spacing: 20){
                    HStack{
                        Text("내 책장")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        NavigationLink(value: ShelfRoute.bookSearch) {
                            Text(" + 새 책 추가") // 이 버튼을 누르면 NavigationStack의 path에 ShelfRoute.bookSearch라는 값을 넣어줘.
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
                                NavigationLink(value: ShelfRoute.bookDetail(book.id)) {
                                    ShelfBookCardView(imageName: book.imageName, author: book.author, title: book.title, onEdit: {
                                        selectedBookToEdit = BookEditTarget(id: book.id)
                                    },
                                    onDelete: {
                                        selectedBookToDelete = book
                                        isShowingDeleteAlert = true
                                    })
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 110)
                    }
                }
            }
            .sheet(item: $selectedBookToEdit) { target in
                if let book = viewModel.books.first(where: { $0.id == target.id }) {
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
            .navigationDestination(for: ShelfRoute.self) { route in
                switch route {
                case .bookSearch:
                    BookSearchView(viewModel: viewModel, selectedTab: $selectedTab, onFinishRegistration: { tab in
                        selectedTab = tab
                        path = NavigationPath()
                    })
                    
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
    ShelfView(viewModel: BookMateViewModel(), selectedTab: .constant(0) )
}
