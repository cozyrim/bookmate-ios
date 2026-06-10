import SwiftUI

struct PublicBookshelfView: View {
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    let targetUser: PublicUserResponse
    
    @State private var books: [Book] = []
    @State private var guestbookMessages: [GuestbookMessageResponse] = []
    @State private var showingGuestbook = false
    @State private var isLoading = false
    
    private let socialService = SocialAPIService()
    private let tokenStore = KeychainTokenStore()
    
    // 🎨 테마에 맞춰 위아래 여백을 채워줄 배경색 
    private var themeBackgroundColor: Color {
        let theme = (targetUser.roomTheme.isEmpty || targetUser.roomTheme == "AppBackground") ? "room_bg_default" : targetUser.roomTheme
        switch theme {
        case "room_bg_pink":
            return Color(red: 251/255, green: 228/255, blue: 228/255)
        case "room_bg_mint":
            return Color(red: 224/255, green: 245/255, blue: 230/255)
        default:
            return Color(red: 254/255, green: 242/255, blue: 229/255)
        }
    }
        
    var body: some View {
        ZStack {
            // 1. 방 테마와 똑같은 배경색을 깔아서 경계선을 없앱니다.
            themeBackgroundColor
                .ignoresSafeArea()
            
            // 2. 미니룸 이미지
            let safeTheme = (targetUser.roomTheme.isEmpty || targetUser.roomTheme == "AppBackground") ? "room_bg_default" : targetUser.roomTheme
            Image(safeTheme)
                .resizable()
                .scaledToFit()
                .offset(y: -40)
            
            // 3. UI 및 책 전시
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                ProfileImageView(
                        imageName: "profileImage",
                        imageURLString: targetUser.profileImageUrl,
                        showsEditIcon: false,
                        size: 50
                    )
                                
                                Text("\(targetUser.nickname)님의 책장")
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                            }
                            .padding(.top, 20)
                            
                            Spacer() // 방 공간
                            
                            
                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    showingGuestbook = true
                                                }) {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "text.book.closed.fill")
                                                        Text("방명록")
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(Color.white)
                                                    .foregroundColor(.blue)
                                                    .clipShape(Capsule()) // 동그라미 말고 예쁜 알약 모양으로!
                                                    .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                                                }
                                                .padding(.trailing, 20)
                                                .padding(.bottom, 15) // 책장과 살짝 간격 띄우기
                                            }
                            
                            
                            
                            // 📚 진짜 책장 선반 느낌의 UI
                            ZStack(alignment: .bottom) {
                                // 책장 뒷배경 (어두운 나무색)
                                Color(red: 110/255, green: 75/255, blue: 50/255)
                                    .frame(height: 180)
                                    .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
                                
                                // 책장 나무 선반 (조금 더 밝은 나무색)
                                Rectangle()
                                    .fill(Color(red: 160/255, green: 110/255, blue: 75/255))
                                    .frame(height: 25)
                                    .overlay( // 선반 입체감을 위한 그림자
                                        Rectangle()
                                            .fill(Color.black.opacity(0.2))
                                            .frame(height: 5),
                                        alignment: .top
                                    )
                                
                                // 읽은 책 표지 나열
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        if books.isEmpty {
                                            ForEach(0..<4, id: \.self) { _ in
                                                BookCoverCell(imageName: "bookPlaceholder", width: 90)
                                                    .shadow(color: .black.opacity(0.4), radius: 5, x: 5, y: 5)
                                            }
                                        } else {
                                            ForEach(books) { book in
                                                NavigationLink(destination: BookDetailView(viewModel: BookMateViewModel(), book: book)) {
                                                    BookCoverCell(imageName: book.imageName, width: 90)
                                                        .shadow(color: .black.opacity(0.4), radius: 5, x: 5, y: 5)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 25)
                                }
                            }
                        }
        }
        .navigationBarTitleDisplayMode(.inline)
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
