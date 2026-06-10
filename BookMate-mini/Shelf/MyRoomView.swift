import SwiftUI

struct MyRoomView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @EnvironmentObject var authViewModel: AuthSessionViewModel
    @Binding var path: NavigationPath
    
    private let tokenStore = KeychainTokenStore()
    private let socialService = SocialAPIService()
    @State private var isSurfing = false
    @State private var surfError: String? = nil
    
    @State private var guestbookMessages: [GuestbookMessageResponse] = []
    @State private var showingGuestbook = false
    
    // 🎨 테마에 맞춰 위아래 여백을 채워줄 배경색
    private var themeBackgroundColor: Color {
        guard let currentUser = authViewModel.currentUser else { return Color("AppBackground") }
        let theme = (currentUser.profileImageUrl == nil && currentUser.nickname.isEmpty) ? "room_bg_default" : "room_bg_default" // FIXME: UserEntity needs roomTheme. Defaulting.
        switch theme {
        case "room_bg_pink":
            return Color(red: 251/255, green: 228/255, blue: 228/255)
        case "room_bg_mint":
            return Color(red: 230/255, green: 247/255, blue: 245/255)
        default:
            return Color(red: 249/255, green: 244/255, blue: 236/255)
        }
    }
    
    var body: some View {
        ZStack {
            // 1. 방 전체 배경색
            themeBackgroundColor
                .ignoresSafeArea()
            
            // 2. 미니룸 이미지
            Image("room_bg_default")
                .resizable()
                .scaledToFit()
                .offset(y: -40)
            
            // 3. UI 및 책 전시
            VStack(spacing: 0) {
                // 상단: 프로필 및 파도타기 버튼
                HStack(spacing: 12) {
                    if let user = authViewModel.currentUser {
                        ProfileImageView(
                            imageName: "profileImage",
                            imageURLString: user.profileImageUrl,
                            showsEditIcon: false,
                            size: 50
                        )
                        
                        Text("\(user.nickname)님의 책장")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // 방 구경 (유저 검색) 버튼
                    NavigationLink(value: ShelfView.ShelfRoute.searchUsers) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
                    }
                    
                    // 파도타기 (랜덤 유저 방문) 버튼
                    Button(action: surfRandomUser) {
                        if isSurfing {
                            ProgressView()
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "water.waves")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
                        }
                    }
                    .disabled(isSurfing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer() // 방 공간
                
                HStack {
                    Spacer()
                    Button(action: {
                        fetchGuestbook()
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
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 15)
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
                            if viewModel.books.isEmpty {
                                ForEach(0..<4, id: \.self) { _ in
                                    BookCoverCell(imageName: "bookPlaceholder", width: 90)
                                        .shadow(color: .black.opacity(0.4), radius: 5, x: 5, y: 5)
                                }
                            } else {
                                ForEach(viewModel.books) { book in
                                    NavigationLink(value: ShelfView.ShelfRoute.bookDetail(book.id)) {
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
        .alert("파도타기 실패", isPresented: Binding(get: { surfError != nil }, set: { _ in surfError = nil })) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(surfError ?? "")
        }
        .sheet(isPresented: $showingGuestbook) {
            if let user = authViewModel.currentUser {
                GuestbookSheetView(
                    messages: $guestbookMessages,
                    targetUser: PublicUserResponse(id: user.id, nickname: user.nickname, profileImageUrl: user.profileImageUrl, roomTheme: "room_bg_default"),
                    socialService: socialService
                )
                .environmentObject(authViewModel)
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func fetchGuestbook() {
        guard let token = tokenStore.load(), let user = authViewModel.currentUser else { return }
        Task {
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
        guard let token = tokenStore.load() else { return }
        isSurfing = true
        
        Task {
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
                    surfError = "방문할 다른 유저를 찾지 못했어요."
                }
            }
        }
    }
}
