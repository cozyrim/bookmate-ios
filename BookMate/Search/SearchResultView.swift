import SwiftUI

struct SearchResultView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @State private var suggestionTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    let onSaveComplete: () -> Void
    let onRegisterBookTap: () -> Void

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                searchHeader

                suggestionList

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if viewModel.isLoading {
                            ProgressView("검색 중...")
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 24)
                        }

                        if let errorMessage = viewModel.searchErrorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color("Error"))
                                .padding(.horizontal, 30)
                        }

                        if let word = viewModel.dictionarySearchResult {
                            Text("\"\(word.text)\"에 대한 검색 결과입니다.")
                                .font(.callout)
                                .foregroundStyle(Color("TextSecondary"))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)

                            DictionaryResultCard(
                                text: word.text,
                                meaning: word.meaning,
                                partOfSpeech: word.partOfSpeech,
                                exampleSentence: word.exampleSentence ?? "예문이 없습니다.",
                                imageName: "기본 이미지",
                                onSaveComplete: onSaveComplete,
                                onRegisterBookTap: onRegisterBookTap,
                                viewModel: viewModel,
                                showingSheet: false
                            )
                            .id(word.targetCode)
                        }
                    }
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.top, 12)
        }
        .onChange(of: viewModel.searchText) { _, newValue in
            scheduleSuggestions(for: newValue)
        }
        .onDisappear {
            suggestionTask?.cancel()
        }
    }

    private var searchHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("TextSecondary").opacity(0.7))

            TextField(
                "",
                text: $viewModel.searchText,
                prompt: Text("사전에서 단어 검색...")
                    .foregroundStyle(Color("TextPrimary").opacity(0.6))
            )
            .focused($isSearchFocused)
            .submitLabel(.search)
            .disabled(viewModel.isLoading)
            .onSubmit {
                runDictionarySearch()
            }

            if !viewModel.searchText.isEmpty {
                Button {
                    clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("TextMuted").opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color("SurfaceSoft"))
        .clipShape(Capsule())
        .padding(.horizontal)
    }

    @ViewBuilder
    private var suggestionList: some View {
        if isSearchFocused && !viewModel.dictionarySuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.dictionarySuggestions, id: \.targetCode) { suggestion in
                    Button {
                        selectSuggestion(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.text)
                                .font(.callout.bold())

                            Text(suggestion.meaning)
                                .font(.caption)
                                .foregroundStyle(Color("TextSecondary"))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color("Surface").opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color("Border").opacity(0.45), lineWidth: 1)
            }
            .padding(.horizontal)
        }
    }

    private func scheduleSuggestions(for newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        suggestionTask?.cancel()

        guard !trimmed.isEmpty else {
            viewModel.dictionarySuggestions = []
            viewModel.dictionarySearchResult = nil
            viewModel.searchErrorMessage = nil
            return
        }

        guard isSearchFocused, trimmed.count >= 2 else {
            viewModel.dictionarySuggestions = []
            return
        }

        viewModel.searchMode = .dictionary

        suggestionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            await viewModel.fetchDictionarySuggestions()
        }
    }

    private func runDictionarySearch() {
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            viewModel.searchErrorMessage = "검색어를 입력해 주세요."
            return
        }

        suggestionTask?.cancel()
        viewModel.searchMode = .dictionary
        viewModel.dictionarySuggestions = []
        isSearchFocused = false

        Task { @MainActor in
            await viewModel.searchDictionaryEntry()
        }
    }

    private func selectSuggestion(_ suggestion: DictionaryEntry) {
        suggestionTask?.cancel()
        viewModel.searchText = suggestion.text
        viewModel.dictionarySuggestions = []
        viewModel.searchErrorMessage = nil
        isSearchFocused = false

        Task { @MainActor in
            await viewModel.selectDictionaryEntry(suggestion)
        }
    }

    private func clearSearch() {
        suggestionTask?.cancel()
        viewModel.searchText = ""
        viewModel.dictionarySuggestions = []
        viewModel.dictionarySearchResult = nil
        viewModel.searchErrorMessage = nil
        viewModel.isLoading = false
    }
}

#Preview {
    SearchResultView(
        viewModel: BookMateViewModel(),
        onSaveComplete: {},
        onRegisterBookTap: {}
    )
}
