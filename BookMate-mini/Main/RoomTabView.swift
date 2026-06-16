import SwiftUI
import Combine

struct RoomTabView: View {
    let viewModel: BookMateViewModel
    @StateObject private var booksStore: MiniRoomBooksStore
    @State private var path = NavigationPath()

    init(viewModel: BookMateViewModel) {
        self.viewModel = viewModel
        _booksStore = StateObject(wrappedValue: MiniRoomBooksStore(viewModel: viewModel))
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            MyRoomView(books: booksStore.books, path: $path)
                .navigationDestination(for: ShelfView.ShelfRoute.self) { route in
                    switch route {
                    case .bookSearch:
                        // 방 구경 탭에서 새 책 추가는 보통 안 하겠지만 혹시 몰라 대응
                        BookSearchView(viewModel: viewModel, selectedTab: .constant(1), onFinishRegistration: { _ in
                            path = NavigationPath()
                        })
                    case .bookDetail(let bookId):
                        if let book = viewModel.book(for: bookId) {
                            BookDetailView(viewModel: viewModel, book: book)
                        } else {
                            Text("책 정보를 찾을 수 없습니다.")
                        }
                    case .publicRoom(let user):
                        PublicBookshelfView(targetUser: user)
                    case .searchUsers:
                        UserSearchView()
                    }
                }
        }
        .onAppear {
            PerformanceLogger.event("MiniRoomTabAppear")
        }
    }
}

@MainActor
private final class MiniRoomBooksStore: ObservableObject {
    @Published private(set) var books: [Book]

    private var cancellable: AnyCancellable?

    init(viewModel: BookMateViewModel) {
        self.books = viewModel.books
        self.cancellable = viewModel.$books
            .removeDuplicates()
            .sink { [weak self] books in
                PerformanceLogger.event("MiniRoomBooksUpdated")
                self?.books = books
            }
    }
}
