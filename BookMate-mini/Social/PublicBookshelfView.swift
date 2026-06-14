import SwiftUI

struct PublicBookshelfView: View {
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    let targetUser: PublicUserResponse
    
    @State private var books: [Book] = []
    @State private var guestbookMessages: [GuestbookMessageResponse] = []
    @State private var showingGuestbook = false
    @State private var isLoading = false
    @State private var selectedBook: Book?
    
    private let socialService = SocialAPIService()
    private let tokenStore = KeychainTokenStore()
    
        
    var body: some View {
        ZStack {
                MiniRoomSceneView(
                    nickname: targetUser.nickname,
                    profileImageUrl: targetUser.profileImageUrl,
                    theme: MiniRoomTheme.from(targetUser.roomTheme),
                    books: books,
                    showsExploreButtons: false,
                    isSurfing: false,
                    onSearchUsers: {},
                    onSurfRandomUser: {},
                    onOpenGuestbook: {
                        showingGuestbook = true
                    },
                    onBookTap: { book in
                        selectedBook = book
                    }
                )

                if isLoading {
                    ProgressView("책장 불러오는 중...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedBook) { book in
                PublicBookDetailView(
                    book: book,
                    ownerNickname: targetUser.nickname
                )
            }
            .onAppear {
                fetchData()
            }
            .sheet(isPresented: $showingGuestbook) {
                GuestbookSheetView(
                    messages: $guestbookMessages,
                    targetUser: targetUser,
                    socialService: socialService
                )
                .environmentObject(authViewModel)
                .presentationDetents([.medium, .large])
            }
        }
    
    private func fetchData() {
        guard let token = tokenStore.load() else { return }
        isLoading = true
        Task {
            do {
                async let fetchedBooks = socialService.fetchPublicBooks(token: token, userId: targetUser.id)
                async let fetchedMessages = socialService.fetchGuestbook(token: token, userId: targetUser.id)
                
                let (bResult, mResult) = try await (fetchedBooks, fetchedMessages)
                
                await MainActor.run {
                    self.books = bResult
                    self.guestbookMessages = mResult
                    self.isLoading = false
                }
            } catch {
                print("로드 실패: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PublicBookshelfView(
            targetUser: PublicUserResponse(
                id: UUID(),
                nickname: "독서왕",
                profileImageUrl: nil,
                roomTheme: "room_bg_default" // 방 색상을 바꿔보며 테스트 해보세요!
            )
        )
        .environmentObject(AuthSessionViewModel())
    }
}
