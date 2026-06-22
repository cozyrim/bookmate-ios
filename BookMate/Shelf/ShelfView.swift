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
    @State private var shelfLayoutStyle: ShelfLayoutStyle = .grid

    private enum ShelfLayoutStyle {
        case grid
        case list

        var toggled: ShelfLayoutStyle {
            self == .grid ? .list : .grid
        }

        var toggleIconName: String {
            self == .grid ? "list.bullet" : "square.grid.2x2"
        }

        var toggleAccessibilityLabel: String {
            self == .grid ? "가로형 보기로 전환" : "세로형 보기로 전환"
        }
    }

    enum ShelfRoute: Hashable {
        case bookSearch
        case bookDetail(UUID)
        case bookDetailMemo(UUID)
        case publicRoom(PublicUserResponse)
        case searchUsers
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

                VStack(spacing: 8){
                    shelfHeader

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



                    } else if viewModel.shelfBooks.isEmpty {
                        Spacer()

                        ContentStateView(type: .empty, iconName: "book", title: "아직 등록한 책이 없어요.", message: "읽고 있는 책을 등록하면\n내 책장에서 관리할 수 있어요.", buttonTitle: "책 등록하기", buttonIconName: "plus", buttonAction: {
                            path.append(ShelfRoute.bookSearch)
                        }
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            shelfContent
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
                        memoTitle: "메모하기",
                        onEdit: {
                            activeBookSheet = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                Task {
                                    await viewModel.loadMyReview(bookId: book.id)
                                    activeBookSheet = .edit(book)
                                }
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
                        },
                        onMemo: {
                            activeBookSheet = nil

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                path.append(ShelfRoute.bookDetailMemo(book.id))
                            }
                        }
                    )
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color("AppBackground"))

                case .edit(let book):
                    BookEditSheet(
                        book: book,
                        isReviewPublic: viewModel.myReview(for: book.id)?.isPublic ?? false
                    ) { editValues in
                        let latestBook = viewModel.books.first(where: { $0.id == book.id }) ?? book
                        let progress = editValues.readingStatus == .completed ? 1.0 : latestBook.progress
                        let currentPage = editValues.readingStatus == .completed
                            ? latestBook.totalPages ?? latestBook.currentPage
                            : latestBook.currentPage

                        let updatedBook = Book(
                            id: latestBook.id,
                            title: latestBook.title,
                            author: latestBook.author,
                            imageName: latestBook.imageName,
                            category: editValues.category,
                            progress: progress,
                            totalPages: latestBook.totalPages,
                            currentPage: currentPage,
                            rating: editValues.rating,
                            review: editValues.review,
                            readingStatus: editValues.readingStatus,
                            startDate: editValues.startDate,
                            endDate: editValues.endDate
                        )

                        activeBookSheet = nil

                        Task {
                            _ = await viewModel.updateBook(updatedBook)
                            _ = await viewModel.saveReview(
                                bookId: updatedBook.id,
                                rating: editValues.rating ?? 0,
                                content: editValues.review ?? "",
                                isPublic: editValues.isReviewPublic
                            )
                        }
                    }
                    .presentationDetents([.large])
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
                            currentPage: currentPage,
                            rating: latestBook.rating,
                            review: latestBook.review,
                            readingStatus: latestBook.readingStatus,
                            startDate: latestBook.startDate,
                            endDate: latestBook.endDate
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
                    if let book = viewModel.book(for: bookId){
                        BookDetailView(viewModel: viewModel, book: book)
                    } else {
                        Text("책 정보를 찾을 수 없습니다.")
                    }

                case .bookDetailMemo(let bookId):
                    if let book = viewModel.book(for: bookId){
                        BookDetailView(
                            viewModel: viewModel,
                            book: book,
                            initialTab: .diary,
                            opensMemoComposerOnAppear: true
                        )
                    } else {
                        Text("책 정보를 찾을 수 없습니다.")
                    }

                case .publicRoom(let user):
                    PublicBookshelfView(targetUser: user)

                case .searchUsers:
                    UserSearchView { user in
                        path.append(ShelfRoute.publicRoom(user))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var shelfContent: some View {
        switch shelfLayoutStyle {
        case .grid:
            HStack(alignment: .top, spacing: 16) {
                LazyVStack(spacing: 18) {
                    ForEach(shelfBooksForColumn(isLeftColumn: true)) { shelfBook in
                        shelfBookCard(for: shelfBook, style: .grid)
                    }
                }
                .frame(maxWidth: .infinity)

                LazyVStack(spacing: 18) {
                    ForEach(shelfBooksForColumn(isLeftColumn: false)) { shelfBook in
                        shelfBookCard(for: shelfBook, style: .grid)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 42)
            }
            .padding(.horizontal, 24)
            .padding(.top, 2)
            .padding(.bottom, 110)

        case .list:
            LazyVStack(spacing: 16) {
                ForEach(viewModel.shelfBooks) { shelfBook in
                    shelfBookCard(for: shelfBook, style: .list)
                }
            }
            .padding(.bottom, 110)
        }
    }

    private var shelfHeader: some View {
        HStack(alignment: .center) {
            Text("내 책장")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            shelfHeaderControls
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var shelfHeaderControls: some View {
        HStack(spacing: 0) {
            NavigationLink(value: ShelfRoute.bookSearch) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))

                    Text("새 책 추가")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color("PrimaryDeep").opacity(0.82))
                .frame(height: 36)
                .padding(.leading, 11)
                .padding(.trailing, 14)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color("Border").opacity(0.32))
                .frame(width: 1, height: 18)

            layoutToggleButton
        }
        .background(Color("Surface").opacity(0.78), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color("Border").opacity(0.24), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.025), radius: 8, x: 0, y: 3)
    }

    private var layoutToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                shelfLayoutStyle = shelfLayoutStyle.toggled
            }
        } label: {
            Image(systemName: shelfLayoutStyle.toggleIconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color("PrimaryDeep").opacity(0.82))
                .frame(width: 40, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(shelfLayoutStyle.toggleAccessibilityLabel)
    }

    private func shelfBooksForColumn(isLeftColumn: Bool) -> [ShelfBook] {
        viewModel.shelfBooks.enumerated().compactMap { index, shelfBook in
            index.isMultiple(of: 2) == isLeftColumn ? shelfBook : nil
        }
    }

    @ViewBuilder
    private func shelfBookCard(for shelfBook: ShelfBook, style: ShelfLayoutStyle) -> some View {
        if let book = viewModel.book(for: shelfBook) {
            switch style {
            case .grid:
                ShelfBookCardView(
                    imageName: book.imageName,
                    author: book.author,
                    title: book.title,
                    category: book.category,
                    progress: shelfBook.progress,
                    wordCount: viewModel.savedWords(for: book.id).count,
                    readingStatus: shelfBook.status,
                    onTap: {
                        path.append(ShelfRoute.bookDetail(book.id))
                    },
                    onMoreTap: {
                        activeBookSheet = .options(book)
                    }
                )
                .buttonStyle(.plain)

            case .list:
                ShelfBookListCardView(
                    imageName: book.imageName,
                    author: book.author,
                    title: book.title,
                    category: book.category,
                    progress: shelfBook.progress,
                    wordCount: viewModel.savedWords(for: book.id).count,
                    readingStatus: shelfBook.status,
                    onTap: {
                        path.append(ShelfRoute.bookDetail(book.id))
                    },
                    onMoreTap: {
                        activeBookSheet = .options(book)
                    }
                )
                .buttonStyle(.plain)
            }
        }
    }
}


#Preview {
    ShelfView(viewModel: BookMateViewModel(), selectedTab: .constant(0) )
}
