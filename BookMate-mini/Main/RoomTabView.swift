import SwiftUI

struct RoomTabView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            MyRoomView(viewModel: viewModel, path: $path)
                .navigationDestination(for: ShelfView.ShelfRoute.self) { route in
                    switch route {
                    case .bookSearch:
                        // 방 구경 탭에서 새 책 추가는 보통 안 하겠지만 혹시 몰라 대응
                        BookSearchView(viewModel: viewModel, selectedTab: .constant(1), onFinishRegistration: { _ in
                            path = NavigationPath()
                        })
                    case .bookDetail(let bookId):
                        if let book = viewModel.books.first(where: { $0.id == bookId }) {
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
    }
}
