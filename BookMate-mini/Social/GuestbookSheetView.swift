import SwiftUI

struct GuestbookSheetView: View {
    @EnvironmentObject var authViewModel: AuthSessionViewModel

    @Binding var messages: [GuestbookMessageResponse]

    let targetUser: PublicUserResponse
    let socialService: SocialAPIService

    @State private var newMessageContent = ""
    @State private var isPosting = false
    @State private var selectedReportTarget: ModerationTarget?
    @State private var pendingBlockMessage: GuestbookMessageResponse?
    @State private var toast: AppToast?

    private let tokenStore = KeychainTokenStore()
    private let moderationService = ModerationAPIService()

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                header
                messageList
                composer
            }
        }
        .appToast($toast)
        .sheet(item: $selectedReportTarget) { target in
            ReportContentSheet(
                target: target,
                moderationService: moderationService
            ) { result in
                hideReportedContent(result)
                toast = AppToast(message: "신고가 접수됐어요.", style: .success)
            }
            .presentationDetents([.large])
        }
        .alert(
            "이 사용자를 차단할까요?",
            isPresented: Binding(
                get: { pendingBlockMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingBlockMessage = nil
                    }
                }
            )
        ) {
            Button("취소", role: .cancel) {
                pendingBlockMessage = nil
            }

            Button("차단", role: .destructive) {
                if let pendingBlockMessage {
                    blockWriter(of: pendingBlockMessage)
                }
            }
        } message: {
            Text("차단하면 이 사용자의 방명록 글이 내 화면에서 숨겨지고, 앞으로 상호작용이 제한돼요.")
        }
        .onAppear {
            PerformanceLogger.event("GuestbookSheetAppear")
        }
    }

    private var header: some View {
        Text("\(targetUser.nickname)님의 방명록")
            .font(.headline.weight(.bold))
            .foregroundStyle(Color("TextPrimary"))
            .padding(.top, 20)
            .padding(.bottom, 12)
    }

    private var messageList: some View {
        List {
            if messages.isEmpty {
                ContentUnavailableView(
                    "아직 방명록이 없어요",
                    systemImage: "heart.text.square",
                    description: Text("첫 방명록을 남겨보세요.")
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 44, leading: 18, bottom: 44, trailing: 18))
            } else {
                ForEach(messages) { message in
                    VStack(spacing: 0) {
                        messageRow(message)

                        if message.id != messages.last?.id {
                            Rectangle()
                                .fill(Color("Border").opacity(0.34))
                                .frame(height: 0.7)
                        }
                    }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                TextField("방명록을 남겨보세요...", text: $newMessageContent, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color("Surface").opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    postMessage()
                } label: {
                    if isPosting {
                        ProgressView()
                            .tint(Color("Primary"))
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.headline)
                            .foregroundStyle(Color("PrimaryButtonText"))
                            .frame(width: 36, height: 36)
                            .background(Color("Primary"), in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(trimmedMessage.isEmpty || isPosting)
                .opacity(trimmedMessage.isEmpty || isPosting ? 0.45 : 1)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(Color("AppBackground").opacity(0.92))
    }

    private var trimmedMessage: String {
        newMessageContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func messageRow(_ message: GuestbookMessageResponse) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ProfileImageView(
                imageName: "profileImage",
                imageURLString: message.writerProfileImageUrl,
                showsEditIcon: false,
                size: 34
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(message.writerNickname)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text(message.content)
                    .font(.callout)
                    .foregroundStyle(Color("TextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(BookMateDateFormatter.serverDateTimeDisplayString(from: message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(Color("TextMuted"))
            }

            Spacer(minLength: 0)

            messageActions(for: message)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func messageActions(for message: GuestbookMessageResponse) -> some View {
        if canDelete(message) || canReport(message) || canBlock(message) {
            Menu {
                if canDelete(message) {
                    Button("삭제하기", role: .destructive) {
                        deleteMessage(messageId: message.id)
                    }
                }

                if canReport(message) {
                    Button("신고하기", role: .destructive) {
                        selectedReportTarget = reportTarget(for: message)
                    }
                }

                if canBlock(message) {
                    Button("이 사용자 차단", role: .destructive) {
                        pendingBlockMessage = message
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
        }
    }

    private func canDelete(_ message: GuestbookMessageResponse) -> Bool {
        authViewModel.currentUser?.id == message.writerId ||
        authViewModel.currentUser?.id == targetUser.id
    }

    private func canReport(_ message: GuestbookMessageResponse) -> Bool {
        guard let currentUserId = authViewModel.currentUser?.id else { return false }
        return currentUserId != message.writerId
    }

    private func canBlock(_ message: GuestbookMessageResponse) -> Bool {
        guard let currentUserId = authViewModel.currentUser?.id else { return false }
        return currentUserId != message.writerId
    }

    private func reportTarget(for message: GuestbookMessageResponse) -> ModerationTarget {
        ModerationTarget(
            targetType: .guestbookMessage,
            targetId: message.id.uuidString,
            targetUserId: message.writerId,
            title: "방명록 신고",
            subtitle: "\(message.writerNickname)님의 방명록 글을 신고합니다.",
            snapshot: [
                "writerNickname": message.writerNickname,
                "content": message.content,
                "createdAt": message.createdAt,
                "roomOwnerId": targetUser.id.uuidString
            ]
        )
    }

    private func postMessage() {
        guard let token = tokenStore.load(), !trimmedMessage.isEmpty else { return }
        isPosting = true

        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("PostGuestbookAPI", id: signpostID)

            defer {
                PerformanceLogger.end("PostGuestbookAPI", id: signpostID)
            }

            do {
                let contentCheck = try await moderationService.checkContent(
                    trimmedMessage,
                    context: .guestbook
                )

                guard contentCheck.allowed else {
                    await MainActor.run {
                        toast = AppToast(
                            message: contentCheck.reasons.first ?? "방명록 내용을 확인해주세요.",
                            style: .error
                        )
                        isPosting = false
                    }
                    return
                }

                let newMessage = try await socialService.writeGuestbook(
                    token: token,
                    userId: targetUser.id,
                    content: trimmedMessage
                )

                await MainActor.run {
                    messages.insert(newMessage, at: 0)
                    newMessageContent = ""
                    isPosting = false
                }
            } catch {
                print("방명록 작성 실패: \(error)")
                await MainActor.run {
                    toast = AppToast(message: "방명록 작성에 실패했어요.", style: .error)
                    isPosting = false
                }
            }
        }
    }

    private func deleteMessage(messageId: UUID) {
        guard let token = tokenStore.load() else { return }

        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("DeleteGuestbookAPI", id: signpostID)

            defer {
                PerformanceLogger.end("DeleteGuestbookAPI", id: signpostID)
            }

            do {
                try await socialService.deleteGuestbook(token: token, messageId: messageId)
                await MainActor.run {
                    messages.removeAll { $0.id == messageId }
                    toast = AppToast(message: "방명록을 삭제했어요.", style: .success)
                }
            } catch {
                print("방명록 삭제 실패: \(error)")
                await MainActor.run {
                    toast = AppToast(message: "방명록 삭제에 실패했어요.", style: .error)
                }
            }
        }
    }

    private func blockWriter(of message: GuestbookMessageResponse) {
        pendingBlockMessage = nil

        Task {
            do {
                _ = try await moderationService.blockUser(userId: message.writerId)

                await MainActor.run {
                    messages.removeAll { $0.writerId == message.writerId }
                    toast = AppToast(message: "\(message.writerNickname)님을 차단했어요.", style: .success)
                }
            } catch {
                await MainActor.run {
                    toast = AppToast(message: "차단에 실패했어요.", style: .error)
                }
            }
        }
    }

    private func hideReportedContent(_ result: ModerationReportEnvelope) {
        if result.report.targetType == .guestbookMessage,
           let messageId = UUID(uuidString: result.report.targetId) {
            messages.removeAll { $0.id == messageId }
        }
    }
}
