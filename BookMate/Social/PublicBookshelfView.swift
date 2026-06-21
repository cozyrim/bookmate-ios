import SwiftUI

struct PublicBookshelfView: View {
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let targetUser: PublicUserResponse

    @State private var books: [Book] = []
    @State private var guestbookMessages: [GuestbookMessageResponse] = []
    @State private var showingGuestbook = false
    @State private var isLoading = false
    @State private var selectedBook: Book?
    @State private var selectedReportTarget: ModerationTarget?
    @State private var showingUserActions = false
    @State private var showingBlockConfirmation = false
    @State private var toast: AppToast?
    @State private var isBlocking = false

    private let socialService = SocialAPIService()
    private let moderationService = ModerationAPIService()
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
                onBack: {
                    dismiss()
                },
                onSearchUsers: {},
                onSurfRandomUser: {},
                onMoreActions: {
                    showingUserActions = true
                },
                onOpenGuestbook: {
                    PerformanceLogger.event("PublicGuestbookTapped")
                    showingGuestbook = true
                },
                onBookTap: { book in
                    PerformanceLogger.event("PublicRoomBookTapped")
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
        .appToast($toast)
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedBook) { book in
            PublicBookDetailView(
                book: book,
                ownerNickname: targetUser.nickname
            )
        }
        .onAppear {
            PerformanceLogger.event("PublicBookshelfAppear")
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
        .sheet(item: $selectedReportTarget) { target in
            ReportContentSheet(
                target: target,
                moderationService: moderationService
            ) { _ in
                toast = AppToast(message: "신고가 접수됐어요.", style: .success)
            }
            .presentationDetents([.large])
        }
        .confirmationDialog(
            "\(targetUser.nickname)님",
            isPresented: $showingUserActions,
            titleVisibility: .visible
        ) {
            Button("신고하기", role: .destructive) {
                selectedReportTarget = userReportTarget
            }

            Button("이 사용자 차단", role: .destructive) {
                showingBlockConfirmation = true
            }

            Button("취소", role: .cancel) { }
        } message: {
            Text("부적절한 콘텐츠를 신고하거나 이 사용자를 내 화면에서 숨길 수 있어요.")
        }
        .alert("이 사용자를 차단할까요?", isPresented: $showingBlockConfirmation) {
            Button("취소", role: .cancel) { }
            Button("차단", role: .destructive) {
                blockTargetUser()
            }
            .disabled(isBlocking)
        } message: {
            Text("차단하면 이 사용자의 공개 책장과 방명록 콘텐츠가 내 화면에서 숨겨져요.")
        }
    }

    private var userReportTarget: ModerationTarget {
        ModerationTarget(
            targetType: .publicBookshelf,
            targetId: targetUser.id.uuidString,
            targetUserId: targetUser.id,
            title: "신고하기",
            subtitle: "\(targetUser.nickname)님의 공개 프로필과 책장을 신고합니다.",
            snapshot: [
                "nickname": targetUser.nickname,
                "profileImageUrl": targetUser.profileImageUrl ?? "",
                "bookCount": "\(books.count)"
            ]
        )
    }

    private func fetchData() {
        guard let token = tokenStore.load() else { return }
        isLoading = true

        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("FetchPublicBookshelfAPI", id: signpostID)

            defer {
                PerformanceLogger.end("FetchPublicBookshelfAPI", id: signpostID)
            }

            do {
                async let fetchedBooks = socialService.fetchPublicBooks(token: token, userId: targetUser.id)
                async let fetchedMessages = socialService.fetchGuestbook(token: token, userId: targetUser.id)

                let (bookResult, messageResult) = try await (fetchedBooks, fetchedMessages)

                await MainActor.run {
                    books = bookResult
                    guestbookMessages = messageResult
                    isLoading = false
                }
            } catch {
                print("로드 실패: \(error)")
                await MainActor.run {
                    isLoading = false
                    toast = AppToast(message: "공개 책장을 불러오지 못했어요.", style: .error)
                }
            }
        }
    }

    private func blockTargetUser() {
        guard !isBlocking else { return }
        isBlocking = true

        Task {
            do {
                _ = try await moderationService.blockUser(userId: targetUser.id)

                await MainActor.run {
                    toast = AppToast(message: "\(targetUser.nickname)님을 차단했어요.", style: .success)
                    isBlocking = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    toast = AppToast(message: "차단에 실패했어요.", style: .error)
                    isBlocking = false
                }
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
                roomTheme: "room_bg_default"
            )
        )
        .environmentObject(AuthSessionViewModel())
    }
}
