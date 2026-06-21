//
//  BookSearchView.swift
//  BookMate
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI

// 책 등록을 위해 검색하고, 검색 결과까지 보여주는 화면
struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var searchTask: Task<Void, Never>?
    @ObservedObject var viewModel: BookMateViewModel

    @Binding var selectedTab: Int
    let onFinishRegistration: (Int) -> Void

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CircleIconButton(systemName: "chevron.left") {
                        dismiss()
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 18)

                SearchTextField(
                    searchText: $query,
                    placeholder: "책 제목 또는 저자를 입력하세요."
                ) {
                    searchBooks()
                }
                .padding(.horizontal, 20)
                .onChange(of: query) { _, newValue in
                    scheduleSearch(for: newValue)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        resultTitleArea
                        resultArea
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 42)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
    }

    @ViewBuilder
    private var resultTitleArea: some View {
        if !trimmedQuery.isEmpty {
            HStack {
                Text("\"\(trimmedQuery)\"에 대한 검색 결과")
                Spacer()
            }
            .font(.callout)
            .foregroundStyle(Color("TextSecondary"))
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var resultArea: some View {
        if viewModel.isBookSearchLoading {
            statusCard(
                iconName: "magnifyingglass",
                title: "책을 찾고 있어요",
                message: "잠시만 기다려 주세요.",
                showsProgress: true
            )
        } else if let errorMessage = viewModel.bookSearchErrorMessage {
            statusCard(
                iconName: "exclamationmark.triangle",
                title: "검색에 실패했어요",
                message: errorMessage,
                foregroundColor: Color("Error"),
                buttonTitle: "다시 검색하기",
                buttonIconName: "arrow.clockwise"
            ) {
                searchBooks()
            }
        } else if trimmedQuery.isEmpty {
            searchGuideArea
        } else if viewModel.bookSearchResults.isEmpty {
            noResultArea
        } else {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.bookSearchResults) { kakaoBook in
                    let draft = BookRegistrationDraft(kakaoBook: kakaoBook)

                    NavigationLink {
                        BookDiscoveryDetailView(
                            viewModel: viewModel,
                            draft: draft,
                            selectedTab: $selectedTab,
                            onFinishRegistration: finishRegistration
                        )
                    } label: {
                        BookSearchResultRow(
                            imageName: draft.imageName,
                            title: draft.title,
                            author: draft.author
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var searchGuideArea: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color("PrimaryDeep"))

                VStack(alignment: .leading, spacing: 7) {
                    Text("검색창에 책 정보를 입력해 주세요")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))

                    Text("책 제목, 저자, 출판사 일부만 입력해도 후보 책을 찾아드릴게요.")
                        .font(.callout)
                        .foregroundStyle(Color("TextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            quickSearchExamples

            Divider()
                .overlay(Color("Border").opacity(0.2))

            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.caption)

                Text("검색해도 책이 없을 때 직접 입력할 수 있어요.")
                    .font(.caption)

                Spacer(minLength: 0)

                manualEntryTextLink
            }
            .foregroundStyle(Color("TextSecondary"))
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color("Surface").opacity(0.88), in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color("Border").opacity(0.18), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private var quickSearchExamples: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("빠른 검색 예시")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextMuted"))

            HStack(spacing: 8) {
                quickSearchButton("데미안")
                quickSearchButton("김영하")
                quickSearchButton("에세이")
            }
        }
    }

    private var manualEntryTextLink: some View {
        NavigationLink {
            BookManualEntryView(
                viewModel: viewModel,
                selectedTab: $selectedTab,
                onFinishRegistration: finishRegistration
            )
        } label: {
            Text("직접 등록")
                .font(.caption.bold())
                .foregroundStyle(Color("PrimaryDeep"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color("Primary").opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var noResultArea: some View {
        statusCard(
            iconName: "book.closed",
            title: "검색 결과가 없어요",
            message: "표지와 제목을 직접 입력해서 내 책장에 등록할 수 있어요.",
            buttonTitle: "직접 등록하기",
            buttonIconName: "square.and.pencil"
        )
    }

    private func quickSearchButton(_ text: String) -> some View {
        Button {
            searchBooks(with: text)
        } label: {
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(Color("PrimaryDeep"))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Color("Primary").opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func manualEntryLink(title: String, isProminent: Bool = false) -> some View {
        NavigationLink {
            BookManualEntryView(
                viewModel: viewModel,
                selectedTab: $selectedTab,
                onFinishRegistration: finishRegistration
            )
        } label: {
            Label(title, systemImage: "square.and.pencil")
                .font(.callout)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isProminent ? Color("Primary") : Color("Primary").opacity(0.16))
                .foregroundStyle(isProminent ? Color("PrimaryButtonText") : Color("PrimaryDeep"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func statusCard(
        iconName: String,
        title: String,
        message: String,
        foregroundColor: Color = Color("PrimaryDeep"),
        showsProgress: Bool = false,
        buttonTitle: String? = nil,
        buttonIconName: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(foregroundColor.opacity(0.14))
                    .frame(width: 80, height: 80)

                if showsProgress {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(foregroundColor)
                }
            }

            VStack(spacing: 7) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text(message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("TextSecondary"))
            }

            if let buttonTitle, let buttonAction {
                Button(action: buttonAction) {
                    Label(buttonTitle, systemImage: buttonIconName ?? "arrow.right")
                        .font(.callout.bold())
                        .foregroundStyle(Color("PrimaryDeep"))
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(Color("Primary").opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain)
            } else if let buttonTitle {
                manualEntryLink(title: buttonTitle)
                    .padding(.top, 2)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("Surface").opacity(0.88), in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color("Border").opacity(0.14), lineWidth: 1)
        }
    }

    private func finishRegistration(to tab: Int) {
        onFinishRegistration(tab)
    }

    private func scheduleSearch(for newValue: String) {
        searchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            viewModel.bookSearchResults = []
            viewModel.bookSearchErrorMessage = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)

            if Task.isCancelled { return }

            await viewModel.searchBooks(query: trimmed)
        }
    }

    private func searchBooks(with text: String? = nil) {
        let searchText = text ?? query
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return }

        if let text {
            query = text
        }

        searchTask?.cancel()

        Task {
            await viewModel.searchBooks(query: normalized)
        }
    }
}

#Preview {
    BookSearchView(
        viewModel: BookMateViewModel(),
        selectedTab: .constant(0),
        onFinishRegistration: { _ in }
    )
}
