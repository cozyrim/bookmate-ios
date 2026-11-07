import SwiftUI

struct MiniRoom3DView: View {
    @ObservedObject var reading: ReadingSessionViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var characterIsMoving = false
    @State private var characterIntent: RoomCharacterController.Intent = .shelf
    @Environment(\.compactTabBarHeight) private var compactTabBarHeight
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
    @State private var viewpoint: MiniRoomViewpoint = .shelf
    private var focused: Bool { viewpoint == .shelf }
    @State private var cameraZoom: Float = 1
    @State private var page = 0
    @State private var opening: UUID?
    @State private var active = true

    private var pageCount: Int { max(1, (books.count + 8) / 9) }
    private var visibleBooks: [Book] { Array(books.dropFirst(min(page, pageCount - 1) * 9).prefix(9)) }

    var body: some View {
        VStack(spacing: 8) {
            roomHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: 652)

            if verticalSizeClass == .compact {
                HStack(alignment: .top, spacing: 8) {
                    scene
                    ScrollView { readingControls }
                        .frame(width: 320)
                }
                .padding(.bottom, 8 + compactTabBarHeight)
            } else {
                scene
                readingControls.padding(.bottom, 8 + compactTabBarHeight)
            }
        }
        .background(sceneBackground.ignoresSafeArea())
        .onAppear { active = true; if reading.active != nil { selectViewpoint(.reading) } }
        .onChange(of: reading.active?.id) { _, id in if id != nil { selectViewpoint(.reading) } }
        .onDisappear { active = false; opening = nil }
        .onChange(of: scenePhase) { _, phase in if phase != .active { opening = nil } }
        .onChange(of: books.map(\.id)) { _, _ in page = min(page, pageCount - 1); opening = nil }
        .tint(Color("PrimaryDeep"))
        .toolbarBackground(.hidden, for: .tabBar)
    }

    private var scene: some View {
        TimelineView(.periodic(from: .now, by: reading.active == nil ? 60 : 1)) { context in
            canvas(at: context.date)
        }
        .colorMultiply(lampIsOn ? .white : Color(red: 0.80, green: 0.84, blue: 0.92))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: lampIsOn)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("원목 서재 3D 공간")
        .accessibilityHint("표지를 누르면 책이 열려요. 좌우로 둘러보고 두 손가락으로 확대하거나 축소할 수 있어요.")
        .accessibilityIdentifier("miniRoom.wood3D.canvas")
    }

    private var readingControls: some View {
        VStack(spacing: 4) {
            ReadingRoomControls(model: reading, books: books,
                                onStart: { selectViewpoint(.reading); characterIntent = .seated },
                                onSit: { selectViewpoint(.reading); characterIntent = .seated },
                                onWalk: { selectViewpoint($0 == .window ? .window : .shelf); characterIntent = $0 })
            roomControls
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: 652)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var sceneBackground: Color {
        colorScheme == .dark
            ? Color(red: 23 / 255, green: 30 / 255, blue: 43 / 255)
            : Color(red: 248 / 255, green: 250 / 255, blue: 253 / 255)
    }

    private var renderedIntent: RoomCharacterController.Intent {
        guard let session = reading.active else { return characterIntent }
        return session.isPaused ? .seated : .reading
    }

    private func canvas(at date: Date) -> some View {
        let session = reading.active
        let timerText: String? = session.map {
            let prefix = $0.isPaused ? "휴식 " : ""
            return prefix + ReadingSession.durationText($0.elapsed(at: date))
        }
        return MiniRoomRealityCanvas(
            books: visibleBooks, viewpoint: viewpoint, opening: $opening,
            active: active && scenePhase == .active, lampIsOn: lampIsOn, reduceMotion: reduceMotion,
            darkMode: colorScheme == .dark, characterIsMoving: $characterIsMoving, characterIntent: renderedIntent,
            timerText: timerText, zoom: $cameraZoom, onHit: handleHit
        )
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
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Menu {
                    ForEach(MiniRoomViewpoint.allCases, id: \.self) { choice in
                        Button { selectViewpoint(choice) } label: {
                            Label(choice.title, systemImage: choice == viewpoint ? "checkmark" : "viewfinder")
                        }
                        .accessibilityIdentifier("room.viewpoint.\(choice.rawValue)")
                    }
                } label: {
                    Label(viewpoint.title, systemImage: "viewfinder")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("시점 선택")
                .accessibilityValue(viewpoint.title)
                .accessibilityIdentifier("room.viewpoint.menu")
                Spacer(minLength: 0)
                Button(action: onOpenGuestbook) {
                    Image(systemName: "heart.text.square").frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("방명록")
                .accessibilityIdentifier("miniRoom.wood3D.guestbook")
                Button(action: toggleLamp) {
                    Image(systemName: lampIsOn ? "lightbulb.fill" : "lightbulb")
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("조명")
                .accessibilityValue(lampIsOn ? "켜짐" : "꺼짐")
                .accessibilityIdentifier("miniRoom.wood3D.lamp")
                zoomButton("축소", symbol: "minus.magnifyingglass", change: -0.15)
                Button { cameraZoom = 1 } label: {
                    Text("\(Int((cameraZoom * 100).rounded()))%")
                        .font(.caption.monospacedDigit())
                        .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("확대 배율 초기화")
                .accessibilityValue("\(Int((cameraZoom * 100).rounded()))퍼센트")
                .accessibilityIdentifier("room.zoom.reset")
                zoomButton("확대", symbol: "plus.magnifyingglass", change: 0.15)
            }
            .disabled(opening != nil)

            HStack(spacing: 4) {
                Text(sceneHint).font(.caption).foregroundStyle(Color("TextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if focused && pageCount > 1 {
                    Button { page -= 1 } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .accessibilityLabel("이전 책장")
                    .disabled(page == 0 || opening != nil)
                    Text("\(page + 1)/\(pageCount)").font(.caption.monospacedDigit())
                    Button { page += 1 } label: {
                        Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .accessibilityLabel("다음 책장")
                    .disabled(page + 1 >= pageCount || opening != nil)
                }
            }
            .padding(.horizontal, 8)
            if voiceOver {
                ScrollView {
                    ForEach(visibleBooks) { book in
                        Button(book.title) { opening = book.id }
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("miniRoom.open.\(book.id)")
                            .disabled(opening != nil)
                    }
                }
                .frame(maxHeight: 88)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color("TextPrimary"))
    }

    private func zoomButton(_ title: String, symbol: String, change: Float) -> some View {
        Button { cameraZoom = MiniRoomCameraRig.clampedZoom(cameraZoom + change) } label: {
            Image(systemName: symbol).font(.footnote.weight(.semibold))
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel(title)
        .accessibilityIdentifier(change > 0 ? "room.zoom.in" : "room.zoom.out")
        .disabled(opening != nil)
    }

    private var sceneHint: String {
        if characterIsMoving { return "자리로 이동하고 있어요." }
        if let session = reading.active { return session.isPaused ? "잠시 쉬고 있어요." : "소파에서 읽고 있어요." }
        if books.isEmpty { return "책을 등록하면 이곳에 꽂혀요." }
        if reduceMotion { return "책을 눌러 기록을 열어보세요." }
        return opening == nil ? "표지를 눌러 펼쳐보세요" : "책을 펼치고 있어요…"
    }

    private func handleHit(_ hit: MiniRoomRealityScene.Hit) {
        switch hit {
        case .book(let id):
            if let book = books.first(where: { $0.id == id }) { onBookTap(book) }
        case .guestbook:
            onOpenGuestbook()
        case .lamp:
            toggleLamp()
        case .seat:
            selectViewpoint(.reading)
            characterIntent = .seated
        }
    }

    private func selectViewpoint(_ value: MiniRoomViewpoint) {
        guard value != viewpoint else { return }
        viewpoint = value
        cameraZoom = 1
        opening = nil
    }

    private func toggleLamp() { lampIsOn.toggle() }
}

