import SwiftUI

struct MiniRoom3DView: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let nickname: String
    let profileImageUrl: String?
    let books: [Book]
    let isSurfing: Bool
    let onSearchUsers: () -> Void
    let onSurfRandomUser: () -> Void
    let onChangeTheme: () -> Void
    let onOpenGuestbook: () -> Void
    let onBookTap: (Book) -> Void

    @State private var lampIsOn = true
    @State private var focused = true
    @State private var page = 0
    @State private var opening: UUID?
    @State private var active = true

    private var pageCount: Int { max(1, (books.count + 8) / 9) }
    private var visibleBooks: [Book] { Array(books.dropFirst(min(page, pageCount - 1) * 9).prefix(9)) }

    var body: some View {
        ZStack {
            MiniRoomRealityCanvas(
                books: visibleBooks, focused: focused, opening: $opening,
                active: active, lampIsOn: lampIsOn, reduceMotion: reduceMotion,
                darkMode: colorScheme == .dark, onHit: handleHit
            )
            // A consistent dusk grade accompanies the practical light on every renderer.
            .colorMultiply(lampIsOn ? .white : Color(red: 0.80, green: 0.84, blue: 0.92))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: lampIsOn)
            .ignoresSafeArea()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("원목 서재 3D 공간")
            .accessibilityHint("책 표지를 누르거나, 좌우로 드래그해 둘러볼 수 있어요.")
            .accessibilityIdentifier("miniRoom.wood3D.canvas")

            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 12) {
                    roomHeader
                    Spacer(minLength: 16)
                    roomControls
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { active = true }
        .onDisappear { active = false; opening = nil }
        .onChange(of: books.map(\.id)) { _, _ in page = min(page, pageCount - 1); opening = nil }
        .tint(Color("PrimaryDeep"))
        .toolbarBackground(.hidden, for: .tabBar)
    }

    private var roomHeader: some View {
        HStack(spacing: 10) {
            ProfileImageView(imageName: "profileImage", imageURLString: profileImageUrl, showsEditIcon: false, size: 32)
            Text("\(nickname)님의 서재")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button(action: onChangeTheme) {
                Image(systemName: "paintpalette").frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel("배경")
            .accessibilityIdentifier("miniRoom.changeTheme")
            Menu {
                Button("다른 서재 찾기", systemImage: "magnifyingglass", action: onSearchUsers)
                Button(isSurfing ? "찾는 중…" : "파도타기", systemImage: "water.waves", action: onSurfRandomUser)
                    .disabled(isSurfing)
            } label: {
                Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel("서재 탐색")
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .foregroundStyle(Color("TextPrimary"))
        .modifier(BookMateGlassSurface())
        .disabled(opening != nil)
    }

    private var roomControls: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Text(sceneHint)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if !books.isEmpty {
                    Button { page -= 1 } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .accessibilityLabel("이전 책장")
                    .disabled(page == 0 || opening != nil)
                    Text("\(page + 1)/\(pageCount)")
                        .font(.caption.monospacedDigit())
                        .accessibilityLabel("\(books.count)권, \(pageCount)개 책장 중 \(page + 1)번째")
                    Button { page += 1 } label: {
                        Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .accessibilityLabel("다음 책장")
                    .disabled(page + 1 >= pageCount || opening != nil)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)

            ViewThatFits {
                HStack(spacing: 2) { roomActions }
                VStack(spacing: 2) { roomActions }
            }
            .disabled(opening != nil)
            if voiceOver {
                ScrollView {
                    ForEach(visibleBooks) { book in
                        Button(book.title) { opening = book.id }
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("miniRoom.open.\(book.id)")
                            .disabled(opening != nil)
                    }
                }
                .frame(maxHeight: 132)
            }
        }
        .padding(6)
        .buttonStyle(.plain)
        .foregroundStyle(Color("TextPrimary"))
        .modifier(BookMateGlassSurface(radius: 26))
    }

    @ViewBuilder
    private var roomActions: some View {
        Button { focused.toggle() } label: {
            actionLabel(focused ? "방 전체" : "책장 가까이", icon: focused ? "viewfinder" : "books.vertical")
        }
        .accessibilityIdentifier("miniRoom.wood3D.books")
        Button(action: onOpenGuestbook) {
            actionLabel("방명록", icon: "heart.text.square")
        }
        .accessibilityIdentifier("miniRoom.wood3D.guestbook")
        Button(action: toggleLamp) {
            actionLabel("조명", icon: lampIsOn ? "lightbulb.fill" : "lightbulb")
        }
        .accessibilityValue(lampIsOn ? "켜짐" : "꺼짐")
        .accessibilityIdentifier("miniRoom.wood3D.lamp")
    }

    private var sceneHint: String {
        if books.isEmpty { return "책을 등록하면 이곳에 꽂혀요." }
        if reduceMotion { return "책을 눌러 기록을 열어보세요." }
        return opening == nil ? "표지를 눌러 펼쳐보세요" : "책을 펼치고 있어요…"
    }

    private func actionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .labelStyle(.titleAndIcon)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
    }

    private func handleHit(_ hit: MiniRoomRealityScene.Hit) {
        switch hit {
        case .book(let id):
            if let book = books.first(where: { $0.id == id }) { onBookTap(book) }
        case .guestbook:
            onOpenGuestbook()
        case .lamp:
            toggleLamp()
        }
    }

    private func toggleLamp() { lampIsOn.toggle() }
}

