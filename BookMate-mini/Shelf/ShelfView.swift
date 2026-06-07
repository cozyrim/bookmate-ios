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


    @State private var activeBookSheet: BookActionSheet?

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
                AppBackgroundView()

                VStack(spacing: 20){
                    HStack{
                        Text("내 책장")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        NavigationLink(value: ShelfRoute.bookSearch) {
                            Text(" + 새 책 추가") // 이 버튼을 누르면 NavigationStack의 path에 ShelfRoute.bookSearch라는 값을 넣어줘.
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(Color("Primary"))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Color("Primary").opacity(0.3), radius: 7, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    if let errorMessage = viewModel.bookLoadErrorMessage {
                        Spacer()

                        ContentStateView(
                            type: .error,
                            iconName: "exclamationmark.triangle",
                            title: "책장을 불러오지 못했어요.",
                            message: errorMessage,
                            buttonTitle: "다시 시도하기",
                            buttonIconName: "arrow.clockwise",
                            buttonAction: {
                                Task {
                                    await viewModel.loadBooks()
                                }
                            }
                        )
                        .padding(.horizontal, 24)

                        Spacer()



                    } else if viewModel.books.isEmpty {
                        Spacer()

                        ContentStateView(type: .empty, iconName: "book", title: "아직 등록한 책이 없어요.", message: "읽고 있는 책을 등록하면\n내 책장에서 관리할 수 있어요.", buttonTitle: "책 등록하기", buttonIconName: "plus", buttonAction: {
                            path.append(ShelfRoute.bookSearch)
                        }
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16){
                                ForEach(viewModel.books) { book in
                                    ShelfBookCardView(imageName: book.imageName, author: book.author, title: book.title, category: book.category, progress: book.progress, wordCount: viewModel.savedWords(for: book.id).count,
                                                      onTap: {
                                        path.append(ShelfRoute.bookDetail(book.id))
                                    },
                                                      onMoreTap: {
                                        activeBookSheet = .options(book)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 110)
                        }
                    }
                }
            }
            .sheet(item: $activeBookSheet) { sheet in
                switch sheet {
                case .options(let book):
                    MoreOptionsSheet(
                        editTitle: "책 수정하기",
                        deleteTitle: "책 삭제하기",
                        moveTitle: "읽은 쪽수 업데이트",
                        onEdit: {
                            activeBookSheet = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                activeBookSheet = .edit(book)
                            }
                        },
                        onDelete: {
                            activeBookSheet = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                selectedBookToDelete = book
                                isShowingDeleteAlert = true
                            }
                        },
                        onMove: {
                            activeBookSheet = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                activeBookSheet = .progress(book)
                            }
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color("AppBackground"))

                case .edit(let book):
                    BookEditSheet(book: book) { selectedCategory in
                        let latestBook = viewModel.books.first(where: { $0.id == book.id }) ?? book

                        let updatedBook = Book(
                            id: latestBook.id,
                            title: latestBook.title,
                            author: latestBook.author,
                            imageName: latestBook.imageName,
                            category: selectedCategory,
                            progress: latestBook.progress,
                            totalPages: latestBook.totalPages,
                            currentPage: latestBook.currentPage
                        )

                        activeBookSheet = nil

                        Task {
                            await viewModel.updateBook(updatedBook)
                        }
                    }
                    .presentationDetents([.height(420)])
                    .presentationDragIndicator(.visible)

                case .progress(let book):
                    ReadingProgressSheet(book: book) { totalPages, currentPage in
                        let progress = Double(currentPage) / Double(totalPages)
                        let latestBook = viewModel.books.first(where: { $0.id == book.id }) ?? book

                        let updatedBook = Book(
                            id: latestBook.id,
                            title: latestBook.title,
                            author: latestBook.author,
                            imageName: latestBook.imageName,
                            category: latestBook.category,
                            progress: progress,
                            totalPages: totalPages,
                            currentPage: currentPage
                        )

                        activeBookSheet = nil

                        Task {
                            await viewModel.updateBook(updatedBook)
                        }
                    }
                    .presentationDetents([.height(430)])
                    .presentationDragIndicator(.visible)
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
