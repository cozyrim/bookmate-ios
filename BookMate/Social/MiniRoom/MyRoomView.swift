import SwiftUI

struct MyRoomView: View {
    let books: [Book]
    @StateObject private var model: MyRoomViewModel
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Binding var path: NavigationPath
    @Binding private var notificationRequest: PushNotificationNavigationRequest?
    
    
    @State private var showingGuestbook = false
    @State private var highlightedGuestbookMessageId: UUID?
    @State private var showingThemePicker = false

    private var currentTheme: MiniRoomTheme {
        MiniRoomTheme.from(authViewModel.profile?.roomTheme ?? authViewModel.currentUser?.roomTheme)
    }

    init(
        books: [Book],
        path: Binding<NavigationPath>,
        notificationRequest: Binding<PushNotificationNavigationRequest?> = .constant(nil),
        dependencies: AppDependencies? = nil
    ) {
        self.books = books
        _model = StateObject(wrappedValue: MyRoomViewModel(dependencies: dependencies ?? AppDependencies()))
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
                        isSurfing: model.isSurfing,
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
            .alert("파도타기 실패", isPresented: Binding(get: { model.surfError != nil }, set: { _ in model.surfError = nil })) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(model.surfError ?? "")
            }
            .sheet(
                isPresented: $showingGuestbook,
                onDismiss: {
                    highlightedGuestbookMessageId = nil
                }
            ) {
                if let user = authViewModel.currentUser {
                    GuestbookSheetView(
                        model: model.guestbook,
                        highlightedMessageId: highlightedGuestbookMessageId,
                        targetUser: PublicUserResponse(
                            id: user.id,
                            nickname: user.nickname,
                            profileImageUrl: user.profileImageUrl,
                            roomTheme: currentTheme.rawValue
                        )
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
        Task { await model.fetchGuestbook(user: authViewModel.currentUser) }
    }
    private func surfRandomUser() {
        Task {
            if let user = await model.surfRandomUser() {
                path.append(ShelfView.ShelfRoute.publicRoom(user))
            }
        }
    }
}
