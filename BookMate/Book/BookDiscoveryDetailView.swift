//
//  BookDiscoveryDetailView.swift
//  BookMate
//
//  Created by 한채림 on 6/13/26.
//

import SwiftUI

struct BookDiscoveryDetailView: View {
    private enum Tab: String, CaseIterable {
        case intro = "책 소개"
        case reviews = "리뷰"
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BookMateViewModel

    let draft: BookRegistrationDraft
    @Binding var selectedTab: Int
    let onFinishRegistration: (Int) -> Void

    @State private var selectedTabItem: Tab = .intro
    @State private var isDescriptionExpanded = false

    private var descriptionText: String {
        let text = draft.contents.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "책 소개가 제공되지 않습니다." : text
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    coverImage

                    VStack(spacing: 8) {
                        Text(draft.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text(draft.author)
                            .font(.callout)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                    .padding(.horizontal, 24)

                    Picker("상세 탭", selection: $selectedTabItem) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    switch selectedTabItem {
                    case .intro:
                        introSection
                    case .reviews:
                        reviewsSection
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .task(id: selectedTabItem) {
            guard selectedTabItem == .reviews else { return }
            PerformanceLogger.event("BookDiscoveryReviewsTabAppear")

            await viewModel.loadPublicReviews(
                isbn: draft.isbn,
                title: draft.title,
                author: draft.author
            )
        }
        .navigationTitle("북메이트")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                BookManualEntryView(
                    viewModel: viewModel,
                    initialDraft: draft,
                    selectedTab: $selectedTab,
                    onFinishRegistration: onFinishRegistration
                )
            } label: {
                Text("내 책장에 등록하기")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryButtonText"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("Primary"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color("AppBackground").opacity(0.96))
        }
    }

    private var coverImage: some View {
        BookCoverCell(imageName: draft.imageName, width: 150)
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("책 소개")
                .font(.caption.bold())
                .foregroundStyle(Color("TextMuted"))

            Text(descriptionText)
                .font(.callout)
                .foregroundStyle(Color("TextSecondary"))
                .lineSpacing(4)
                .lineLimit(isDescriptionExpanded ? nil : 6)

            if descriptionText.count > 120 {
                Button(isDescriptionExpanded ? "접기" : "더보기") {
                    withAnimation {
                        isDescriptionExpanded.toggle()
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(Color("Primary"))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 24)
    }

    private var reviewsSection: some View {
        VStack(spacing: 12) {
            if viewModel.isPublicReviewLoading {
                ProgressView("리뷰 불러오는 중...")
                    .padding(.top, 32)
            } else if let message = viewModel.publicReviewErrorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.top, 32)
            } else if viewModel.publicBookReviews.isEmpty {
                ContentStateView(
                    type: .empty,
                    iconName: "text.bubble",
                    title: "아직 공개 리뷰가 없어요.",
                    message: "이 책을 읽은 사람들이 공개한 리뷰가 여기에 보여요.",
                    buttonTitle: nil,
                    buttonIconName: nil,
                    buttonAction: nil
                )
            } else {
                HStack {
                        Text("공개 리뷰 \(viewModel.publicBookReviews.count)개")
                            .font(.caption.bold())
                            .foregroundStyle(Color("TextMuted"))

                        Spacer()
                    }

                ForEach(viewModel.publicBookReviews) { review in
                    NavigationLink {
                            PublicReviewDetailView(
                                review: review,
                                bookTitle: draft.title
                            )
                        } label: {
                            PublicReviewCardView(review: review)
                        }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}
