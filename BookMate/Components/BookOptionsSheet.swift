import SwiftUI

/// Quick book actions share the same library update path as the detail screen.
struct BookOptionsSheet: View {
    @ObservedObject var library: BookLibraryViewModel
    let bookID: UUID
    let editTitle: String
    let deleteTitle: String
    let moveTitle: String?
    let memoTitle: String?
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    let onMemo: () -> Void
    @State private var saving = false
    @State private var error: String?
    @State private var pendingStatus: ReadingStatus?
    @State private var confirmsReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let book = library.book(for: bookID) {
                    Text("독서 상태").font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Button {
                                let resets = (book.progress > 0 || (book.currentPage ?? 0) > 0) && (status == .wantToRead || (book.progress >= 0.999 && status != .completed))
                                if resets && book.readingStatus != status {
                                    pendingStatus = status
                                    confirmsReset = true
                                } else { save(status) }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(status.displayName)
                                    if book.readingStatus == status { Image(systemName: "checkmark") }
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(book.readingStatus == status ? Color("Primary") : Color("TextSecondary"))
                            .accessibilityIdentifier("book.status.\(status.rawValue)")
                            .accessibilityAddTraits(book.readingStatus == status ? .isSelected : [])
                        }
                    }
                    if book.progress >= 0.999 {
                        Text("완독에서 다른 상태로 바꾸면 진행률이 0%부터 다시 시작해요.")
                            .font(.caption).foregroundStyle(Color("TextSecondary"))
                    }
                    if let error { Text(error).font(.caption).foregroundStyle(Color("Error")) }
                    if saving { ProgressView().accessibilityLabel("독서 상태 저장 중") }
                    Divider()
                }
                MoreOptionsSheet(editTitle: editTitle, deleteTitle: deleteTitle,
                                 moveTitle: moveTitle, memoTitle: memoTitle,
                                 onEdit: onEdit, onDelete: onDelete, onMove: onMove, onMemo: onMemo)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .disabled(saving)
        .interactiveDismissDisabled(saving)
        .confirmationDialog("진행률을 0%로 바꿀까요?", isPresented: $confirmsReset, titleVisibility: .visible) {
            Button("진행률 초기화", role: .destructive) {
                if let status = pendingStatus { save(status) }
                pendingStatus = nil
            }
            Button("취소", role: .cancel) { pendingStatus = nil }
        } message: {
            Text("이 상태로 바꾸면 읽은 쪽수와 진행률이 초기화돼요. 감상평과 메모는 유지돼요.")
        }
    }

    private func save(_ status: ReadingStatus) {
        saving = true
        error = nil
        Task {
            let success = await library.changeReadingStatus(bookID: bookID, to: status)
            saving = false
            if !success { error = "상태를 저장하지 못했어요. 다시 선택해 주세요." }
        }
    }

}
