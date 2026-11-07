import SwiftUI

struct ReadingRoomControls: View {
    @ObservedObject var model: ReadingSessionViewModel
    let books: [Book]
    let onStart: () -> Void
    let onSit: () -> Void
    let onWalk: (RoomCharacterController.Intent) -> Void
    @State private var selectedID: UUID?
    @State private var showsHistory = false

    private var selectedBook: Book? {
        books.first(where: { $0.id == selectedID })
            ?? books.first(where: { $0.readingStatus == .reading }) ?? books.first
    }

    private var historyButton: some View {
        Button { showsHistory = true } label: {
            Label("독서 기록", systemImage: "clock").font(.caption).frame(minHeight: 44)
        }
        .accessibilityIdentifier("reading.history")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let session = model.active {
                HStack {
                    Text(session.bookTitle).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    historyButton
                }
                HStack {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(ReadingSession.durationText(session.elapsed(at: context.date)))
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .accessibilityIdentifier("reading.timer")
                    }
                    Spacer()
                    Button(session.isPaused ? "계속 읽기" : "잠시 쉬기") {
                        if session.isPaused { model.resume() } else { model.pause() }
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("reading.pause")
                    Button("종료") { _ = model.finish() }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("reading.finish")
                }

            } else {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(books) { book in
                            Button(book.title) { selectedID = book.id }
                        }
                    } label: {
                        HStack {
                            Text(selectedBook?.title ?? "책을 먼저 추가해 주세요").lineLimit(1)
                            Image(systemName: "chevron.down").font(.caption)
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .disabled(books.isEmpty)
                    .accessibilityLabel("읽을 책 선택")
                    Button("읽기 시작") {
                        if let book = selectedBook, model.start(book: book) { onStart() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: 72, minHeight: 44)
                    .disabled(selectedBook == nil || !model.isLoaded)
                    .accessibilityIdentifier("reading.start")
                }
            }
            if model.active == nil {
                HStack(spacing: 12) {
                    Menu {
                        Button("소파에 앉기", action: onSit)
                        Button("책장 앞으로") { onWalk(.shelf) }
                        Button("창가로") { onWalk(.window) }
                    } label: {
                        Label("이동", systemImage: "figure.walk").frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("reading.move")
                    Spacer()
                    historyButton
                }
                .font(.caption.weight(.medium))
            }
            if let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(Color("Error"))
                if !model.isLoaded {
                    Button("다시 불러오기") { model.selectOwner(model.ownerID) }.frame(minHeight: 44)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .foregroundStyle(Color("TextPrimary"))
        .buttonStyle(.plain)
        .modifier(BookMateGlassSurface(radius: 24))
        .sheet(isPresented: $showsHistory) {
            ReadingSessionHistoryView(model: model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct ReadingSessionHistoryView: View {
    @ObservedObject var model: ReadingSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if model.history.isEmpty {
                        Text("독서를 마치면 책별로 시간이 기록돼요.")
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    ForEach(model.history) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.bookTitle).font(.headline)
                            HStack {
                                Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text(ReadingSession.durationText(session.accumulatedSeconds)).monospacedDigit()
                            }
                            .font(.subheadline).foregroundStyle(Color("TextSecondary"))
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .accessibilityIdentifier("reading.record.\(session.id)")
                    }
                } footer: {
                    Text("이 기기에 저장된 기록이에요. 계정과 서버 환경별로 구분되며 다른 기기와는 아직 동기화되지 않아요.")
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackgroundView() }
            .navigationTitle("독서 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
        }
    }
}
