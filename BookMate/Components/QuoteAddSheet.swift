import SwiftUI

struct QuoteAddSheet: View {
    @ObservedObject var viewModel: BookMateViewModel
    let bookId: UUID

    var body: some View {
        QuoteComposer(title: "문장 추가", bookTitle: viewModel.book(for: bookId)?.title) { text, page, memo in
            await viewModel.saveQuote(bookId: bookId, text: text, page: page, memo: memo)
        }
    }
}

/// Presentation-only draft. Saving remains in the injected quote feature/repository path.
struct QuoteComposer: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let bookTitle: String?
    let onSave: @MainActor (String, Int?, String?) async -> Bool
    @State private var text: String
    @State private var pageText: String
    @State private var memo: String
    @State private var isSaving = false
    @State private var saveError: String?
    @FocusState private var focusedField: Field?
    private enum Field { case text, page, memo }

    init(title: String, bookTitle: String?, text: String = "", page: Int? = nil, memo: String? = nil,
         onSave: @escaping @MainActor (String, Int?, String?) async -> Bool) {
        self.title = title
        self.bookTitle = bookTitle
        self.onSave = onSave
        _text = State(initialValue: text)
        _pageText = State(initialValue: page.map(String.init) ?? "")
        _memo = State(initialValue: memo ?? "")
    }

    private var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var pageIsValid: Bool { pageText.isEmpty || Int(pageText) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let bookTitle {
                        Label(bookTitle, systemImage: "book.closed")
                            .font(.subheadline).foregroundStyle(Color("TextSecondary"))
                            .lineLimit(2)
                    }
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("다시 읽고 싶은 문장을 남겨보세요.")
                                .foregroundStyle(Color("TextSecondary"))
                                .padding(.horizontal, 17).padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $text)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(height: 208)
                            .focused($focusedField, equals: .text)
                            .accessibilityLabel("문장")
                            .accessibilityIdentifier("quote.text")
                    }
                    .font(.body)
                    .background(Color("Surface").opacity(0.6), in: .rect(cornerRadius: ReadingStyle.fieldRadius))
                    .foregroundStyle(Color("TextPrimary"))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("페이지").font(.subheadline.weight(.medium))
                            Spacer()
                            TextField("선택", text: $pageText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100, height: 44)
                                .focused($focusedField, equals: .page)
                                .accessibilityIdentifier("quote.page")
                            Text("쪽").foregroundStyle(Color("TextSecondary"))
                        }
                        Divider()
                        if !pageIsValid {
                            Text("페이지는 숫자로 입력해 주세요.")
                                .font(.caption).foregroundStyle(Color("Error"))
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("내 생각").font(.subheadline.weight(.medium))
                        TextField("이 문장이 마음에 남은 이유 (선택)", text: $memo, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.body)
                            .focused($focusedField, equals: .memo)
                            .accessibilityIdentifier("quote.memo")
                    }
                }
                .padding(24)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                .disabled(isSaving)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color("AppBackground").ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let saveError {
                    Text(saveError).font(.callout).foregroundStyle(Color("Error"))
                        .accessibilityIdentifier("quote.error")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Color("AppBackground"))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "저장 중…" : "저장", action: save)
                        .disabled(isSaving || trimmedText.isEmpty || !pageIsValid)
                        .accessibilityIdentifier("quote.save")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("입력 완료") { focusedField = nil }
                }
            }
        }
        .tint(Color("PrimaryDeep"))
        .interactiveDismissDisabled(isSaving)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(ReadingStyle.cardRadius)
    }

    private func save() {
        guard !isSaving, !trimmedText.isEmpty, pageIsValid else { return }
        isSaving = true
        saveError = nil
        let savedText = trimmedText
        let savedPage = Int(pageText)
        let savedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { @MainActor in
            let success = await onSave(savedText, savedPage, savedMemo.isEmpty ? nil : savedMemo)
            isSaving = false
            if success { dismiss() }
            else { saveError = "저장하지 못했어요. 입력한 내용은 그대로 있으니 다시 시도해 주세요." }
        }
    }
}
