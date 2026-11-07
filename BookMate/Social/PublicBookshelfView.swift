import SwiftUI

struct PublicBookshelfView: View {
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let targetUser: PublicUserResponse

    @State private var showingGuestbook = false
    @State private var selectedBook: Book?
    @State private var selectedReportTarget: ModerationTarget?
    @State private var showingUserActions = false
    @State private var showingBlockConfirmation = false


    @StateObject private var model: PublicBookshelfViewModel

    init(targetUser: PublicUserResponse, dependencies: AppDependencies? = nil) {
        self.targetUser = targetUser
        _model = StateObject(wrappedValue: PublicBookshelfViewModel(targetUser: targetUser, dependencies: dependencies ?? AppDependencies()))
    }

    var body: some View {
        ZStack {
            MiniRoomSceneView(
                nickname: targetUser.nickname,
                profileImageUrl: targetUser.profileImageUrl,
                theme: MiniRoomTheme.from(targetUser.roomTheme),
                books: model.books,
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

            if model.isLoading {
                ProgressView("책장 불러오는 중...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .appToast($model.toast)
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preference(key: CompactTabBarHiddenKey.self, value: true)
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
                model: model.guestbook,
                highlightedMessageId: nil,
                targetUser: targetUser
            )
            .environmentObject(authViewModel)
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedReportTarget) { target in
            ReportContentSheet(
                target: target,
                moderationService: model.dependencies.moderation
            ) { _ in
                model.toast = AppToast(message: "신고가 접수됐어요.", style: .success)
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
            .disabled(model.isBlocking)
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
                "bookCount": "\(model.books.count)"
            ]
        )
    }

    private func fetchData() { model.fetchData() }
    private func blockTargetUser() {
        Task {
            if await model.blockTargetUser() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { dismiss() }
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
