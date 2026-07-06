import SwiftUI

struct MyRoomView: View {
    let books: [Book]
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Binding var path: NavigationPath
    @Binding private var notificationRequest: PushNotificationNavigationRequest?
    
    private let tokenStore = KeychainTokenStore()
    private let socialService = SocialAPIService()
    @State private var isSurfing = false
    @State private var surfError: String? = nil
    
    @State private var guestbookMessages: [GuestbookMessageResponse] = []
    @State private var showingGuestbook = false
    @State private var highlightedGuestbookMessageId: UUID?
    @State private var showingThemePicker = false

    private var currentTheme: MiniRoomTheme {
        MiniRoomTheme.from(authViewModel.profile?.roomTheme ?? authViewModel.currentUser?.roomTheme)
    }

    init(
        books: [Book],
        path: Binding<NavigationPath>,
        notificationRequest: Binding<PushNotificationNavigationRequest?> = .constant(nil)
    ) {
        self.books = books
        self._path = path
        self._notificationRequest = notificationRequest
    }
    
    var body: some View {
        Group {
                if let user = authViewModel.currentUser {
                    MiniRoomSceneView(
                        nickname: user.nickname,
                        profileImageUrl: user.profileImageUrl,
                        theme: currentTheme,
                        books: books,
                        showsExploreButtons: true,
                        isSurfing: isSurfing,
                        onSearchUsers: {
                            PerformanceLogger.event("MiniRoomSearchUsersTapped")
                            path.append(ShelfView.ShelfRoute.searchUsers)
                        },
                        onSurfRandomUser: {
                            surfRandomUser()
                        },
                        onChangeTheme: {
                            PerformanceLogger.event("MiniRoomThemePickerTapped")
                            showingThemePicker = true
                        },
                        onOpenGuestbook: {
                            PerformanceLogger.event("MiniRoomGuestbookTapped")
                            highlightedGuestbookMessageId = nil
                            fetchGuestbook()
                            showingGuestbook = true
                        },
                        onBookTap: { book in
                            PerformanceLogger.event("MiniRoomOwnBookTapped")
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
            .sheet(
                isPresented: $showingGuestbook,
                onDismiss: {
                    highlightedGuestbookMessageId = nil
                }
            ) {
                if let user = authViewModel.currentUser {
                    GuestbookSheetView(
                        messages: $guestbookMessages,
                        highlightedMessageId: highlightedGuestbookMessageId,
                        targetUser: PublicUserResponse(
                            id: user.id,
                            nickname: user.nickname,
                            profileImageUrl: user.profileImageUrl,
                            roomTheme: currentTheme.rawValue
                        ),
                        socialService: socialService
                    )
                    .environmentObject(authViewModel)
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showingThemePicker) {
                MiniRoomThemePickerView(selectedTheme: currentTheme)
                    .environmentObject(authViewModel)
                    .presentationDetents([.large])
            }
            .onAppear {
                handleNotificationRequestIfNeeded()
            }
            .onChange(of: notificationRequest?.id) { _, _ in
                handleNotificationRequestIfNeeded()
            }
        }

    private func handleNotificationRequestIfNeeded() {
        guard let notificationRequest else {
            return
        }

        switch notificationRequest.destination {
        case .myGuestbook(let messageId):
            PerformanceLogger.event("NotificationGuestbookOpened")
            path = NavigationPath()
            highlightedGuestbookMessageId = messageId
            fetchGuestbook()
            showingGuestbook = true
            self.notificationRequest = nil
        }
    }
    
    private func fetchGuestbook() {
        guard let token = tokenStore.load(), let user = authViewModel.currentUser else { return }
        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("FetchMyGuestbookAPI", id: signpostID)

            defer {
                PerformanceLogger.end("FetchMyGuestbookAPI", id: signpostID)
            }

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
        guard !isSurfing else { return }

        guard let token = tokenStore.load() else {
            surfError = "로그인이 필요해요."
            return
        }

        isSurfing = true
        
        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("SurfRandomUserAPI", id: signpostID)

            defer {
                PerformanceLogger.end("SurfRandomUserAPI", id: signpostID)
            }

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
                    surfError = error.bookMateUserMessage(fallback: "방문할 다른 유저를 찾지 못했어요.")
                }
            }
        }
    }
}
