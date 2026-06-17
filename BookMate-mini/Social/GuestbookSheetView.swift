import SwiftUI

struct GuestbookSheetView: View {
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Binding var messages: [GuestbookMessageResponse]
    let targetUser: PublicUserResponse
    let socialService: SocialAPIService
    
    @State private var newMessageContent = ""
    @State private var isPosting = false
    private let tokenStore = KeychainTokenStore()

    var body: some View {
        VStack {
            Text("\(targetUser.nickname)님의 방명록")
                .font(.headline)
                .padding(.top, 20)
            
            List {
                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 8) {
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

                                Text(message.content)
                                    .font(.body)

                                Text(BookMateDateFormatter.serverDateTimeDisplayString(from: message.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(Color("TextMuted"))
                            }
                            
                            Spacer()
                            
                            if authViewModel.currentUser?.id == message.writerId ||
                                authViewModel.currentUser?.id == targetUser.id {
                                Button(role: .destructive) {
                                    deleteMessage(messageId: message.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            
            Divider()
            
            HStack {
                TextField("방명록을 남겨보세요...", text: $newMessageContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    postMessage()
                }) {
                    if isPosting {
                        ProgressView()
                            .padding(.horizontal, 10)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                    }
                }
                .disabled(newMessageContent.trimmingCharacters(in: .whitespaces).isEmpty || isPosting)
            }
            .padding()
        }
        .onAppear {
            PerformanceLogger.event("GuestbookSheetAppear")
        }
    }
    
    private func postMessage() {
        guard let token = tokenStore.load() else { return }
        isPosting = true
        
        Task {
            let signpostID = PerformanceLogger.makeSignpostID()
            PerformanceLogger.begin("PostGuestbookAPI", id: signpostID)

            defer {
                PerformanceLogger.end("PostGuestbookAPI", id: signpostID)
            }

            do {
                let newMessage = try await socialService.writeGuestbook(
                    token: token,
                    userId: targetUser.id,
                    content: newMessageContent
                )
                await MainActor.run {
                    self.messages.insert(newMessage, at: 0)
                    self.newMessageContent = ""
                    self.isPosting = false
                }
            } catch {
                print("방명록 작성 실패: \(error)")
                await MainActor.run { isPosting = false }
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
                    self.messages.removeAll { $0.id == messageId }
                }
            } catch {
                print("방명록 삭제 실패: \(error)")
            }
        }
    }
}
