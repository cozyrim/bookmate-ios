//
//  HomeView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var viewModel: BookMateViewModel // 다른 곳에서 만든 viewModel 받아서 관찰
    @Binding var selectedTab: Int
    @State private var path = NavigationPath()
    @State private var activeBookSheet: BookActionSheet?
    private enum NextBookAction {
        case edit(Book)
        case delete(Book)
        case progress(Book)
        case memo(Book)
    }

    @State private var nextBookAction: NextBookAction?
    @State private var isShowingDeleteAlert = false
    @State private var selectedBookToDelete: Book?

//    private struct BookEditTarget: Identifiable {
//        let id: UUID
//    }

    @State private var selectedBookToEdit: Book?
    @State private var reviewWordFocusID: UUID?
    @State private var isShowingNotificationInbox = false
    @State private var isNotificationInboxPanelPresented = false
    @State private var isPreparingNotificationInbox = false

    @StateObject private var notificationModel: NotificationInboxViewModel

    init(viewModel: BookMateViewModel, selectedTab: Binding<Int>) {
        self.viewModel = viewModel
        self._selectedTab = selectedTab
        _notificationModel = StateObject(wrappedValue: NotificationInboxViewModel(
            repository: viewModel.dependencies.notifications, context: viewModel.context
        ))
    }

    private enum HomeRoute: Hashable {
        case bookSearch
        case bookDetail(UUID)
        case bookDetailMemo(UUID)
    }

    private var isSearchActive: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || viewModel.isLoading
        || viewModel.isBookSearchLoading
        || !viewModel.dictionarySuggestions.isEmpty
        || !viewModel.bookSearchResults.isEmpty
        || !viewModel.savedWordSearchResults.isEmpty
        || !viewModel.savedBookSearchResults.isEmpty
    }

    private var shouldShowStarterGuide: Bool {
        viewModel.savedWords.isEmpty && viewModel.shelfBooks.isEmpty
    }

    private var readingBooks: [Book] {
        Array(viewModel.booksOnShelf.lazy
            .filter { ($0.readingStatus ?? .reading) == .reading }
            .prefix(5))
    }


    private var wordsToReview: [Word] {
        viewModel.savedWords
    }

    private var reviewWordIDs: [UUID] {
        wordsToReview.map(\.id)
    }

    private var reviewWordsScrollHeight: CGFloat? {
        switch wordsToReview.count {
        case 0...1:
            return nil
        case 2:
            return 202
        default:
            return 292
        }
    }

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

                        HomeSearchSection(viewModel: viewModel, selectedTab: $selectedTab,
                                          onRegisterBookTap: {
                            BMAnalytics.bookCreateEntryTap(entryPoint: "home_search_section")
                            path.append(HomeRoute.bookSearch)
                        }
                        )

                        if !isSearchActive {
                            if shouldShowStarterGuide {
                                homeStarterGuideCard
                                    .padding(.horizontal, 24)
                                    .padding(.top, 2)
                                    .padding(.bottom, 8)
                            }

                            readingShelfSection
                            reviewWordsSection
                        }

                    }
                    .buttonStyle(.plain)

                }
                .buttonStyle(.plain)
                .scrollDismissesKeyboard(.interactively)

                if isShowingNotificationInbox {
                    notificationInboxOverlay
                        .zIndex(10)
                }
            }
            .sheet(
                item: $activeBookSheet,
                onDismiss: handleBookSheetDismiss
            ) { sheet in
                switch sheet {
                case .options(let book):
                    BookOptionsSheet(
                        library: viewModel.libraryFeature,
                        bookID: book.id,
                        editTitle: "책 수정하기",
                        deleteTitle: "책 삭제하기",
                        moveTitle: "읽은 쪽수 업데이트",
                        memoTitle: "메모하기",
                        onEdit: {
                            nextBookAction = .edit(book)
                            activeBookSheet = nil
                        },
                        onDelete: {
                            nextBookAction = .delete(book)
                            activeBookSheet = nil
                        },
                        onMove: {
                            nextBookAction = .progress(book)
                            activeBookSheet = nil
                        },
                        onMemo: {
                            nextBookAction = .memo(book)
                            activeBookSheet = nil
                        }
                    )
                    .presentationDetents([.height(540), .large])
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
                        let readingStatus: ReadingStatus?

                        if latestBook.readingStatus == .wantToRead && currentPage > 0 {
                            readingStatus = progress >= 0.999 ? .completed : .reading
                        } else {
                            readingStatus = latestBook.readingStatus
                        }

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
                            readingStatus: readingStatus,
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
            .sheet(isPresented: $viewModel.isWordSaveResumeSheetPresented) {
                wordSaveResumeSheet
                    .presentationDragIndicator(.visible)
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

                        guard viewModel.shouldResumeWordSaveAfterBookRegistration else { return }

                        dismissKeyboard()

                        Task { @MainActor in
                            await viewModel.loadBooks()
                            try? await Task.sleep(nanoseconds: 320_000_000)
                            viewModel.presentWordSaveAfterBookRegistration(registeredBookId: nil)
                        }
                    }
                    )
                case .bookDetail(let bookId):
                    if let book = viewModel.book(for: bookId) {
                        BookDetailView(viewModel: viewModel, book: book)
                    } else {
                        Text("책 정보를 찾을 수 없습니다.")
                    }
                case .bookDetailMemo(let bookId):
                    if let book = viewModel.book(for: bookId) {
                        BookDetailView(
                            viewModel: viewModel,
                            book: book,
                            initialTab: .diary,
                            opensMemoComposerOnAppear: true
                        )
                    } else {
                        Text("책 정보를 찾을 수 없습니다.")
                    }
                }
            }
            .task {
                await loadUnreadNotificationCount()
            }
        }
    }

    @ViewBuilder
    private var wordSaveResumeSheet: some View {
        if let word = viewModel.dictionarySearchResult {
            SaveWordSheet(
                viewModel: viewModel,
                text: word.text,
                meaning: word.meaning,
                imageName: "기본 이미지",
                onSaveComplete: {},
                onRegisterBookTap: {
                    path.append(HomeRoute.bookSearch)
                }
            )
        } else {
            VStack(spacing: 12) {
                Text("저장할 단어를 찾지 못했습니다.")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Text("단어를 다시 검색해 주세요.")
                    .font(.callout)
                    .foregroundStyle(Color("TextSecondary"))
            }
            .padding(24)
            .presentationDetents([.height(180)])
        }
    }

    private func handleBookSheetDismiss() {
        guard let action = nextBookAction else { return }

        nextBookAction = nil

        switch action {
        case .edit(let book):
            Task {
                await viewModel.loadMyReview(bookId: book.id)
                activeBookSheet = .edit(book)
            }

        case .delete(let book):
            selectedBookToDelete = book
            isShowingDeleteAlert = true

        case .progress(let book):
            activeBookSheet = .progress(book)

        case .memo(let book):
            path.append(HomeRoute.bookDetailMemo(book.id))
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private var reviewWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 저장 단어")
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

            if wordsToReview.isEmpty {
                recentWordsPlaceholderCard
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(wordsToReview.enumerated()), id: \.element.id) { index, word in
                                NavigationLink {
                                    WordDetailsView(viewModel: viewModel, word: word)
                                } label: {
                                    WordCardView(word: word, isFeatured: isFocusedReviewWord(word, at: index))
                                }
                                .buttonStyle(.plain)
                                .id(word.id)
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        BMAnalytics.wordCardTap(entryPoint: "home_recent_words")
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 2)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $reviewWordFocusID)
                    .frame(height: reviewWordsScrollHeight, alignment: .top)
                    .animation(.snappy(duration: 0.22), value: reviewWordFocusID)
                    .onAppear {
                        scrollToFirstReviewWord(proxy)
                    }
                    .onChange(of: reviewWordIDs) { _, _ in
                        scrollToFirstReviewWord(proxy)
                    }
                }
                .overlay(alignment: .bottom) {
                    if wordsToReview.count > 3 {
                        LinearGradient(
                            colors: [Color("AppBackground").opacity(0), Color("AppBackground").opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 28)
                        .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var readingShelfSection: some View {
        let books = readingBooks

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(viewModel.books.isEmpty ? "내 책장" : "이어서 읽어요")
                    .font(.title2.weight(.medium))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                shelfHeaderActions
            }

            if !books.isEmpty {
                HomeReadingCarousel(books: books, onOpen: openReadingBook) { book in
                    activeBookSheet = .options(book)
                }
            } else if viewModel.books.isEmpty {
                emptyBooksPlaceholderCard
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("읽는 중인 책이 없어요")
                        .font(.headline)
                        .foregroundStyle(Color("TextPrimary"))
                    Text("책장에서 다음에 읽을 책을 골라보세요.")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextSecondary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color("Surface"), in: RoundedRectangle(cornerRadius: ReadingStyle.cardRadius))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func openReadingBook(_ book: Book) {
        BMAnalytics.bookCardTap(entryPoint: "home", readingStatus: .reading)
        path.append(HomeRoute.bookDetail(book.id))
    }

    private var shelfHeaderActions: some View {
        HStack(spacing: 10) {
            NavigationLink(value: HomeRoute.bookSearch) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("책 추가")
            .simultaneousGesture(
                TapGesture().onEnded {
                    BMAnalytics.bookCreateEntryTap(entryPoint: "home_shelf_header")
                }
            )

            if !viewModel.books.isEmpty {
                Rectangle()
                    .fill(Color("TextSecondary").opacity(0.28))
                    .frame(width: 1, height: 13)

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
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("책장 더보기")
            }
        }
    }

    private func isFocusedReviewWord(_ word: Word, at index: Int) -> Bool {
        reviewWordFocusID == word.id || (reviewWordFocusID == nil && index == 0)
    }

    private func scrollToFirstReviewWord(_ proxy: ScrollViewProxy) {
        guard let firstID = reviewWordIDs.first else {
            reviewWordFocusID = nil
            return
        }

        reviewWordFocusID = firstID

        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.22)) {
                proxy.scrollTo(firstID, anchor: .top)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 90)

    }

    private var emptyBooksPlaceholderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color("Primary"))
                .frame(width: 38, height: 38)
                .background(Color("PrimarySoft").opacity(0.55))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("아직 등록한 책이 없어요")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("책을 등록하면 내 책장에 보여요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(Color("Surface").opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: ReadingStyle.cardRadius))
            .shadow(color: Color("Shadow").opacity(0.045), radius: 9, x: 0, y: 3)
    }

    private var homeStarterGuideCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("Primary"))
                    .frame(width: 42, height: 42)
                    .background(Color("Primary").opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("처음엔 단어 하나부터 찾아볼까요?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))

                    Text("궁금한 단어를 검색하고, 저장할 책은 바로 등록할 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                starterKeywordButton("희망")
                starterKeywordButton("행복")

                Button {
                    path.append(HomeRoute.bookSearch)
                } label: {
                    Label("책 등록", systemImage: "plus")
                        .font(.caption.bold())
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color("Primary"), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface").opacity(0.9), in: RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous)
                .stroke(Color("Border").opacity(0.28), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private func starterKeywordButton(_ keyword: String) -> some View {
        Button {
            viewModel.searchMode = .dictionary
            viewModel.searchText = keyword

            Task {
                await viewModel.performSearch()
            }
        } label: {
            Text(keyword)
                .font(.caption.bold())
                .foregroundStyle(Color("PrimaryDeep"))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(Color("Primary").opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }


    private var homeIntroHeader: some View {
        HStack(spacing: 14) {
            Image("BookMateSymbolIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            Text("bookmate")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("TextPrimary"))

            Spacer(minLength: 8)

            notificationBellButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var notificationBellButton: some View {
        Button {
            openNotificationInbox()
        } label: {
            ZStack(alignment: .topTrailing) {
                Group {
                    if isPreparingNotificationInbox {
                        ProgressView()
                            .tint(Color("TextSecondary"))
                            .scaleEffect(0.75)
                    } else {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(Color("TextSecondary"))
                .frame(width: 38, height: 38)
                .background(Color("Surface").opacity(0.84), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color("Border").opacity(0.25), lineWidth: 1)
                }

                if notificationModel.unreadCount > 0 {
                    Text(unreadNotificationBadgeText)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .frame(minWidth: 16, minHeight: 16)
                        .padding(.horizontal, notificationModel.unreadCount > 9 ? 3 : 0)
                        .background(Color("Primary"), in: Capsule())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isPreparingNotificationInbox)
        .accessibilityLabel(notificationModel.unreadCount > 0 ? "새 알림 \(notificationModel.unreadCount)개" : "알림")
    }

    private var unreadNotificationBadgeText: String {
        notificationModel.unreadCount > 99 ? "99+" : "\(notificationModel.unreadCount)"
    }

    private var notificationInboxOverlay: some View {
        GeometryReader { proxy in
            let panelHeight = min(proxy.size.height * 0.66, 580)
            let panelTopPadding = max(proxy.safeAreaInsets.top + 38, 86)

            ZStack(alignment: .top) {
                Color.black.opacity(isNotificationInboxPanelPresented ? 0.34 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeNotificationInbox()
                    }

                NotificationInboxView(
                    viewModel: viewModel,
                    model: notificationModel,
                    onClose: closeNotificationInbox
                ) { notification in
                    PushNotificationRouter.shared.route(userInfo: notification.userInfo)
                }
                .frame(maxWidth: .infinity)
                .frame(height: panelHeight)
                .clipShape(RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous))
                .shadow(color: Color("Shadow").opacity(0.18), radius: 24, x: 0, y: 14)
                .padding(.horizontal, 18)
                .padding(.top, panelTopPadding)
                .compositingGroup()
                .offset(y: isNotificationInboxPanelPresented ? 0 : -(panelHeight + panelTopPadding + 28))
            }
        }
        .ignoresSafeArea()
    }

    private var notificationPanelOpenAnimation: Animation {
        .spring(response: 0.58, dampingFraction: 0.92, blendDuration: 0.08)
    }

    private var notificationPanelCloseAnimation: Animation {
        .spring(response: 0.36, dampingFraction: 0.96, blendDuration: 0.04)
    }

    private func openNotificationInbox() {
        guard !isShowingNotificationInbox, !isPreparingNotificationInbox else { return }

        Task {
            await prepareAndOpenNotificationInbox()
        }
    }

    @MainActor
    private func prepareAndOpenNotificationInbox() async {
        isPreparingNotificationInbox = true
        isNotificationInboxPanelPresented = false
        await notificationModel.loadNotifications()
        isPreparingNotificationInbox = false
        isShowingNotificationInbox = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            guard isShowingNotificationInbox else { return }

            withAnimation(notificationPanelOpenAnimation) {
                isNotificationInboxPanelPresented = true
            }
        }
    }

    private func closeNotificationInbox() {
        guard isShowingNotificationInbox else { return }

        withAnimation(notificationPanelCloseAnimation) {
            isNotificationInboxPanelPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            guard !isNotificationInboxPanelPresented else { return }

            isShowingNotificationInbox = false

            Task {
                await loadUnreadNotificationCount()
            }
        }
    }

    @MainActor
    private func loadUnreadNotificationCount() async { await notificationModel.loadUnreadCount() }

}


#Preview {
    HomeView(viewModel: BookMateViewModel(), selectedTab: .constant(0))
}
