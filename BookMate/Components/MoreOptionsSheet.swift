import SwiftUI

struct MoreOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let editTitle: String
    let deleteTitle: String
    let moveTitle: String?
    let memoTitle: String?
    let horizontalInset: CGFloat
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    let onMemo: () -> Void

    init(editTitle: String = "단어 수정하기", deleteTitle: String = "단어 삭제하기",
         moveTitle: String? = "다른 책으로 이동", memoTitle: String? = nil,
         horizontalInset: CGFloat = 20,
         onEdit: @escaping () -> Void, onDelete: @escaping () -> Void,
         onMove: @escaping () -> Void = {}, onMemo: @escaping () -> Void = {}) {
        self.editTitle = editTitle
        self.deleteTitle = deleteTitle
        self.moveTitle = moveTitle
        self.memoTitle = memoTitle
        self.horizontalInset = horizontalInset
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onMove = onMove
        self.onMemo = onMemo
    }

    var body: some View {
        VStack(spacing: 0) {
            optionRow(editTitle, icon: "pencil", action: onEdit)
            if let moveTitle {
                rowDivider
                optionRow(moveTitle, icon: "rectangle.portrait.and.arrow.right", action: onMove)
            }
            if let memoTitle {
                rowDivider
                optionRow(memoTitle, icon: "note.text.badge.plus", action: onMemo)
            }
            rowDivider
            optionRow(deleteTitle, icon: "trash", destructive: true, action: onDelete)
            Button("취소") { dismiss() }
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.top, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color("TextPrimary"))
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, 10)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(ReadingStyle.cardRadius)
        .presentationDragIndicator(.visible)
    }

    private var rowDivider: some View { Divider().padding(.leading, 48) }

    private func optionRow(_ title: String, icon: String, destructive: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(role: destructive ? .destructive : nil, action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16, weight: .medium)).frame(width: 24)
                Text(title).font(.callout.weight(.medium))
                Spacer()
            }
            .foregroundStyle(destructive ? Color("Error") : Color("TextPrimary"))
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
    }
}
