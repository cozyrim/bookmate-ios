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
    @State private var activeBookSheet: BookActionSheet?
    @State private var isShowingDeleteAlert = false
    @State private var selectedBookToDelete: Book?

//    private struct BookEditTarget: Identifiable {
//        let id: UUID
//    }

    @State private var selectedBookToEdit: Book?

    private enum HomeRoute: Hashable {
        case bookSearch
        case bookDetail(UUID)
    }

    private let recentWordRows = [
        GridItem(.fixed(90), spacing: 12),
        GridItem(.fixed(90), spacing: 12)
    ]


    var body: some View {
        NavigationStack(path: $path){

            ZStack{
//                Image("자연4")
//                    .resizable()
//                    .scaledToFill()
//                    .ignoresSafeArea()
//                Color("Surface").opacity(0.15)
//                //                    Color("AppBackground")
//                    .ignoresSafeArea()
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        homeIntroHeader

                        HomeSearchSection(viewModel: viewModel)

                        VStack(alignment: .leading, spacing: 18){
                            HStack {
                                Text("최근 저장한 단어")
                                    .font(.title2)
                                    .fontWeight(.medium)

                                Spacer()

                                if !viewModel.savedWords.isEmpty {
                                    Button {
                                        selectedTab = 2
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("더보기")
                                                .font(.caption)
                                                .fontWeight(.semibold)

                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .fontWeight(.semibold)

                                        }
                                        .foregroundStyle(Color("TextSecondary"))
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 22)
                            .padding(.bottom, 16)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                if viewModel.savedWords.isEmpty {
                                    HStack {
                                        recentWordsPlaceholderCard
                                    }
                                    .padding(.horizontal, 24)
                                } else {
                                    LazyHGrid(rows: recentWordRows, spacing: 12) {
                                        ForEach(viewModel.savedWords.prefix(8)) { word in
                                            NavigationLink {
                                                WordDetailsView(viewModel: viewModel, word: word)
                                            } label: {
                                                WordCardView(word: word)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
//                        .frame(height: 90)
                        .frame(height: 192)

                        HStack {
                            Text("내 책장")
                                .font(.title3)
                                .fontWeight(.medium)

                            Spacer()


                                Button {
                                    selectedTab = 1
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("더보기")
                                            .font(.caption)
                                            .fontWeight(.semibold)

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(Color("TextSecondary"))
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        ForEach(viewModel.books) { book in
                            BookCardView(
                                imageName: book.imageName,
                                title: book.title,
                                author: book.author,
                                progress: book.progress,
                                category: book.category,
                                onTap: {
                                        path.append(HomeRoute.bookDetail(book.id))
                                    }, // 카드 눌렀을 때 상세 이동.
                                    onMoreTap: {
                                        activeBookSheet = .options(book)
                                    } // 점 버튼 눌렀을 때 메뉴 시트 열기.
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
                                .foregroundStyle(Color("Primary"))
                                .shadow(color: Color("Primary").opacity(0.08), radius: 14, x: 0, y: 8)
                                .padding()
                        } // 이 버튼을 누르면 path에 HomeRoute.bookSearch 라는 값을 넣어줘.
                        // 그 값을 받으면 어디로 갈지는 아래에서 정함
                        .padding(.trailing, 24)

                    }

                }
                .buttonStyle(.plain)

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
                            progress: latestBook.progress
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

    private var recentWordsPlaceholderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color("Primary"))
                .frame(width: 36, height: 36)
                .background(Color("PrimarySoft").opacity(0.55))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("저장한 단어가 없어요")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("검색한 단어를 저장하면 여기에 보여요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(width: 285, height: 90)
        .background(Color("Surface").opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 34))
        .shadow(color: Color("Shadow").opacity(0.045), radius: 9, x: 0, y: 3)
    }

    private var homeIntroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘의 단어장")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))

            Text("읽다가 만난 단어들")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 2)
    }
}


#Preview {
    HomeView(viewModel: BookMateViewModel(), selectedTab: .constant(0))
}
