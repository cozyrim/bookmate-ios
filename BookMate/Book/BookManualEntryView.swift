import SwiftUI
import PhotosUI
import UIKit

struct BookManualEntryView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @StateObject private var registration: BookRegistrationViewModel
    @State private var presentationID = UUID()
    @State private var title: String
    @State private var author: String
    @State private var category: String
    @State private var totalPagesText: String
    @State private var showOptionalFields = false
    @State private var isLoadingTotalPages = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCoverImage: UIImage?
    private let initialDraft: BookRegistrationDraft?
    @Binding var selectedTab: Int
    let onFinishRegistration: (Int) -> Void

    init(viewModel: BookMateViewModel, initialDraft: BookRegistrationDraft? = nil,
         selectedTab: Binding<Int>, onFinishRegistration: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.initialDraft = initialDraft
        self._selectedTab = selectedTab
        self.onFinishRegistration = onFinishRegistration
        _registration = StateObject(wrappedValue: BookRegistrationViewModel(
            library: viewModel.libraryFeature, metadata: viewModel.dependencies.bookMetadata
        ))
        _title = State(initialValue: initialDraft?.title ?? "")
        _author = State(initialValue: initialDraft?.author ?? "")
        let initialCategory = initialDraft?.category ?? "기타"
        _category = State(initialValue: initialCategory == "카테고리 선택" ? "기타" : initialCategory)
        _totalPagesText = State(initialValue: initialDraft?.totalPages.map(String.init) ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !registration.isSaving
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        cover
                    }
                    .accessibilityLabel("책 표지 선택")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("새 책 등록").font(.title2.bold())
                        Text("제목과 저자만 입력해도 등록할 수 있어요.")
                            .font(.callout).foregroundStyle(Color("TextSecondary"))
                    }
                }
                field("책 제목", text: $title, placeholder: "제목을 입력하세요", icon: "book.closed")
                field("저자", text: $author, placeholder: "저자를 입력하세요", icon: "person")
                DisclosureGroup("선택 정보", isExpanded: $showOptionalFields) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("카테고리").font(.subheadline.weight(.medium))
                            Menu {
                                ForEach(["소설", "에세이", "인문", "자기계발", "과학", "기타"], id: \.self) { value in
                                    Button(value) { category = value }
                                }
                            } label: {
                                HStack {
                                    Text(category)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                                }
                                .foregroundStyle(Color("TextPrimary"))
                                .padding(.horizontal, 14).frame(minHeight: 50)
                                .modifier(ReadingSurface(radius: 12))
                            }
                            .accessibilityLabel("카테고리, \(category)")
                        }
                        field("전체 쪽수", text: $totalPagesText,
                              placeholder: isLoadingTotalPages ? "쪽수 불러오는 중..." : "예: 320", icon: "123.rectangle")
                            .keyboardType(.numberPad)
                    }
                    .padding(.top, 16)
                }
                .font(.subheadline).tint(Color("TextSecondary"))

                if let message = registration.errorMessage {
                    Text(message).font(.callout).foregroundStyle(Color("TextSecondary"))
                        .accessibilityIdentifier("book.registration.error")
                }
                Button(action: save) {
                    Text(registration.isSaving ? "등록 중..." : "등록하기")
                        .font(.headline).frame(maxWidth: .infinity).frame(minHeight: 50)
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .background(Color("Primary"), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).disabled(!canSave).opacity(canSave ? 1 : 0.5)
                .accessibilityIdentifier("book.registration.manualSave")
            }
            .padding(24)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("책 등록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .preference(key: CompactTabBarHiddenKey.self, value: true)
        .onDisappear { presentationID = UUID() }
        .task { await fillTotalPagesIfNeeded() }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                selectedCoverImage = image
            }
        }
    }

    @ViewBuilder private var cover: some View {
        if let selectedCoverImage {
            Image(uiImage: selectedCoverImage).resizable().scaledToFit()
                .frame(width: 90, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else if let initialDraft {
            BookCoverCell(imageName: initialDraft.imageName, width: 108)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "camera").font(.title3)
                Text("표지 선택").font(.caption)
            }
            .foregroundStyle(Color("TextSecondary"))
            .frame(width: 90, height: 126)
            .modifier(ReadingSurface(radius: 4))
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.weight(.medium)).foregroundStyle(Color("TextSecondary"))
            ManualBookInputField(text: text, placeholder: placeholder, iconName: icon)
        }
    }

    private func save() {
        guard canSave else { return }
        let pages = totalPagesText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pages.isEmpty && (Int(pages) == nil || (Int(pages) ?? 0) <= 0) {
            showOptionalFields = true
            registration.errorMessage = "전체 쪽수는 1 이상의 숫자로 입력해주세요."
            return
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        BMAnalytics.bookCreateEntryTap(entryPoint: "book_manual_entry")
        let draft = BookRegistrationDraft(
            title: title, author: author, publisher: initialDraft?.publisher ?? "",
            contents: initialDraft?.contents ?? "", imageName: initialDraft?.imageName ?? "책기본이미지",
            category: category, isbn: initialDraft?.isbn ?? "", totalPages: Int(pages)
        )
        let activePresentation = presentationID
        Task {
            await registration.register(draft: draft)
            guard presentationID == activePresentation, let savedBook = registration.savedBook else { return }
            onFinishRegistration(viewModel.completeBookRegistration(savedBook))
        }
    }

    private func fillTotalPagesIfNeeded() async {
        guard totalPagesText.isEmpty, let isbn = initialDraft?.isbn, !isbn.isEmpty else { return }
        isLoadingTotalPages = true
        defer { isLoadingTotalPages = false }
        if let pages = await registration.lookupPageCount(isbn: isbn),
           totalPagesText.isEmpty, !Task.isCancelled {
            totalPagesText = String(pages)
        }
    }
}
