//
//  BookSearchView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI

// 책 등록을 위해 검색하고, 검색 결과까지 보여주는 화면
struct BookSearchView: View {
    //    let imageName: String
    //    let title: String
    //    let author: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var searchTask: Task<Void, Never>? // 이전에 실행 중이던 검색 예약
    @ObservedObject var viewModel: BookMateViewModel
    @Binding var selectedTab: Int
    // @Published에 의해서 값이 바뀌면 ViewModel을 보고 있는 View들이 다시 그려짐

//    Task = 비동기 작업 시작
//    await = API 결과 올 때까지 기다림
//    viewModel.searchBooks = 검색 실행
//    bookSearchResults = 결과 저장
//    @Published = 바뀐 걸 View에 알림
//    ForEach = 결과 개수만큼 카드 그림
    let onFinishRegistration: (Int) -> Void

    private func finishRegistration(to tab: Int) {
        onFinishRegistration(tab)
    }



    var body: some View {
        ZStack{
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    CircleIconButton(systemName: "chevron.left") {
                        dismiss()
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)

                SearchTextField(
                    searchText: $query,
                    placeholder: "책 제목 또는 저자를 입력하세요."
                ) { // 버튼이나 텍스트 필드의 클로저는 기본적으로 async가 아니라서 비동기 작업을 시작하려면 Task로 감싼다
                    Task{
                        await viewModel.searchBooks(query: query)
                    }
                }
                .padding(.horizontal)
                .onChange(of: query) { _, newValue in
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
                resultTitleArea

                resultArea

                manualEntryArea

                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
    }
    private var resultTitleArea: some View {
        HStack {
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(query)\"에 대한 검색 결과")
            } else {
                Text("")
            }

            Spacer()
        }
        .font(.callout)
        .foregroundStyle(Color("TextSecondary"))
        .padding(.horizontal, 24)
        .frame(height: 42)
    }


        private var resultArea: some View {
            ScrollView {
                LazyVStack(spacing: 10){// bookSearchResults는 @Published라서 SwiftUI가 변화를 감지
                    if viewModel.isBookSearchLoading {
                        ProgressView("책 검색 중...")
                            .padding(.top, 40)
                    } else if let errorMessage = viewModel.bookSearchErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color("Error"))
                            .padding(.top, 40)
                    } else if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, viewModel.bookSearchResults.isEmpty {
                        Text("검색 결과가 없어요.")
                            .font(.callout)
                            .foregroundStyle(Color("TextSecondary"))
                            .padding(.top, 40)

                    } else {
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
                                BookSearchResultRow(imageName: draft.imageName, title: draft.title, author: draft.author)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 430)
        }

        private var manualEntryArea: some View {
            VStack(spacing: 6){
                Text("원하는 책이 없나요?")
                    .font(.callout)
                    .foregroundStyle(Color("TextSecondary"))


                NavigationLink {
                    BookManualEntryView(viewModel: viewModel, selectedTab: $selectedTab, onFinishRegistration: finishRegistration)
                } label: {
                    Text("직접 입력해서 등록하기")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("PrimaryDeep"))
                        .underline()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
}





#Preview {
    BookSearchView(viewModel: BookMateViewModel(), selectedTab: .constant(0), onFinishRegistration: { _ in})
}
