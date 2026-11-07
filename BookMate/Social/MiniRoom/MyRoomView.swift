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
    @State private var roomWith3DEnabled: String?

    private var currentTheme: MiniRoomTheme {
        MiniRoomTheme.from(authViewModel.profile?.roomTheme ?? authViewModel.currentUser?.roomTheme)
    }

    private var roomPreferenceKey: String? {
        authViewModel.currentUser.map { user in
            "bookmate.miniRoom.wood3D.\(APIEnvironment.currentEnvironment.rawValue).\(user.id)"
        }
    }

    private var usesWoodRoom: Bool {
        roomPreferenceKey != nil && roomPreferenceKey == roomWith3DEnabled
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
                if usesWoodRoom {
                    MiniRoom3DView(
                        nickname: user.nickname,
                        profileImageUrl: user.profileImageUrl,
                        books: books,
                        isSurfing: model.isSurfing,
                        onSearchUsers: searchUsers,
                        onSurfRandomUser: surfRandomUser,
                        onChangeTheme: changeTheme,
                        onOpenGuestbook: openGuestbook,
                        onBookTap: openBook
                    )
                } else {
                    MiniRoomSceneView(
                        nickname: user.nickname,
                        profileImageUrl: user.profileImageUrl,
                        theme: currentTheme,
                        books: books,
                        showsExploreButtons: true,
                        isSurfing: model.isSurfing,
                        onSearchUsers: searchUsers,
                        onSurfRandomUser: surfRandomUser,
                        onChangeTheme: changeTheme,
                        onOpenGuestbook: openGuestbook,
                        onBookTap: openBook
                    )
                }
            } else {
                AppBackgroundView()
            }
        }
            .onChange(of: roomPreferenceKey, initial: true) { _, key in
                roomWith3DEnabled = key.flatMap { UserDefaults.standard.bool(forKey: $0) ? $0 : nil }
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
                MiniRoomThemePickerView(
                    currentTheme: currentTheme,
                    usesWoodRoom: usesWoodRoom,
                    onApplyWoodRoom: setWoodRoom
                )
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

    private func setWoodRoom(_ enabled: Bool) {
        guard let key = roomPreferenceKey else { return }
        UserDefaults.standard.set(enabled, forKey: key)
        roomWith3DEnabled = enabled ? key : nil
    }

    private func searchUsers() {
        PerformanceLogger.event("MiniRoomSearchUsersTapped")
        path.append(ShelfView.ShelfRoute.searchUsers)
    }

    private func changeTheme() {
        PerformanceLogger.event("MiniRoomThemePickerTapped")
        showingThemePicker = true
    }

    private func openGuestbook() {
        PerformanceLogger.event("MiniRoomGuestbookTapped")
        highlightedGuestbookMessageId = nil
        fetchGuestbook()
        showingGuestbook = true
    }

    private func openBook(_ book: Book) {
        PerformanceLogger.event("MiniRoomOwnBookTapped")
        path.append(ShelfView.ShelfRoute.bookDetail(book.id))
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
