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
                        HStack {
                            ProfileImageView(imageName: "profileImage",
                                             imageURLString: message.writerProfileImageUrl,
                                             showsEditIcon: false
                                         )
                                         .scaleEffect(0.3)
                            Text(message.writerNickname)
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // 👉 authViewModel.currentUser 로 접근
                            if authViewModel.currentUser?.id == message.writerId || authViewModel.currentUser?.id == targetUser.id {
                                Button(role: .destructive, action: {
                                    deleteMessage(messageId: message.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        Text(message.content)
                            .font(.body)
                        Text(message.createdAt)
                            .font(.caption2)
                            .foregroundColor(.gray)
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
    }
    
    private func postMessage() {
        guard let token = tokenStore.load() else { return }
        isPosting = true
        
        Task {
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
