import SwiftUI

struct MyRoomView: View {
    let books: [Book]
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Binding var path: NavigationPath
    
    private let tokenStore = KeychainTokenStore()
    private let socialService = SocialAPIService()
    @State private var isSurfing = false
    @State private var surfError: String? = nil
    
    @State private var guestbookMessages: [GuestbookMessageResponse] = []
    @State private var showingGuestbook = false
    
    var body: some View {
        Group {
                if let user = authViewModel.currentUser {
                    MiniRoomSceneView(
                        nickname: user.nickname,
                        profileImageUrl: user.profileImageUrl,
                        theme: .basic,
                        books: books,
                        showsExploreButtons: true,
                        isSurfing: isSurfing,
                        onSearchUsers: {
                            path.append(ShelfView.ShelfRoute.searchUsers)
                        },
                        onSurfRandomUser: {
                            surfRandomUser()
                        },
                        onOpenGuestbook: {
                            fetchGuestbook()
                            showingGuestbook = true
                        },
                        onBookTap: { book in
                            path.append(ShelfView.ShelfRoute.bookDetail(book.id))
                        }
                    )
                } else {
                    AppBackgroundView()
                }
            }
            .alert("파도타기 실패", isPresented: Binding(get: { surfError != nil }, set: { _ in surfError = nil })) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(surfError ?? "")
            }
            .sheet(isPresented: $showingGuestbook) {
                if let user = authViewModel.currentUser {
                    GuestbookSheetView(
                        messages: $guestbookMessages,
                        targetUser: PublicUserResponse(
                            id: user.id,
                            nickname: user.nickname,
                            profileImageUrl: user.profileImageUrl,
                            roomTheme: "room_bg_default"
                        ),
                        socialService: socialService
                    )
                    .environmentObject(authViewModel)
                    .presentationDetents([.medium, .large])
                }
            }
        }
    
    private func fetchGuestbook() {
        guard let token = tokenStore.load(), let user = authViewModel.currentUser else { return }
        Task {
            do {
                let messages = try await socialService.fetchGuestbook(token: token, userId: user.id)
                await MainActor.run {
                    self.guestbookMessages = messages
                }
            } catch {
                print("방명록 로드 실패:", error)
            }
        }
    }
    
    private func surfRandomUser() {
        guard let token = tokenStore.load() else { return }
        isSurfing = true
        
        Task {
            do {
                let randomUser = try await socialService.getRandomUser(token: token)
                await MainActor.run {
                    isSurfing = false
                    // NavigationStack의 path를 이용하여 이동
                    path.append(ShelfView.ShelfRoute.publicRoom(randomUser))
                }
            } catch {
                await MainActor.run {
                    isSurfing = false
                    surfError = "방문할 다른 유저를 찾지 못했어요."
                }
            }
        }
    }
}
