//
//  BookEditSheet.swift
//  BookMate
//
//  Created by 한채림 on 5/29/26.
//

import SwiftUI

struct BookEditValues {
    let category: String
    let rating: Int?
    let review: String?
    let isReviewPublic: Bool
    let readingStatus: ReadingStatus?
    let startDate: String?
    let endDate: String?
}

struct BookEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isReviewFocused: Bool

    let book: Book
    let onSave: (BookEditValues) -> Void

    @State private var selectedCategory: String
    @State private var selectedReadingStatus: ReadingStatus?
    @State private var rating: Int
    @State private var reviewText: String
    @State private var isReviewPublic: Bool
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isShowingReadingPeriodPicker = false

    private let categories = ["카테고리 선택", "소설", "에세이", "인문", "자기계발", "과학", "기타"]

    init(
        book: Book,
        isReviewPublic: Bool = false,
        onSave: @escaping (BookEditValues) -> Void
    ) {
        self.book = book
        self.onSave = onSave
        _selectedCategory = State(initialValue: book.category)
        _selectedReadingStatus = State(initialValue: book.readingStatus)
        _rating = State(initialValue: book.rating ?? 0)
        _reviewText = State(initialValue: book.review ?? "")
        _isReviewPublic = State(initialValue: isReviewPublic)
        _startDate = State(initialValue: BookMateDateFormatter.date(from: book.startDate))
        _endDate = State(initialValue: BookMateDateFormatter.date(from: book.endDate))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("책 수정하기")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 28)

                    bookSummary
                    categorySection
                    readingStatusSection
                    ratingSection
                    readingPeriodSection
                    reviewSection
                    reviewPublicSection
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 24)
            }

            saveButton
                .padding(.horizontal, 26)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(Color("AppBackground"))
        }
        .background(Color("AppBackground"))
        .sheet(isPresented: $isShowingReadingPeriodPicker) {
            ReadingPeriodPickerSheet(startDate: $startDate, endDate: $endDate)
                .presentationDetents([.large])
        }
    }

    private var bookSummary: some View {
        HStack(spacing: 16) {
            BookCoverCell(imageName: book.imageName, width: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(Color("TextPrimary").opacity(0.55))
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("카테고리 (선택)")

            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(category) {
                        selectedCategory = category
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory)
                        .foregroundStyle(
                            selectedCategory == "카테고리 선택"
                            ? Color("TextMuted")
                            : Color("PrimaryDeep")
                        )

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color("Primary"))
                }
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(Color("Surface").opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("독서 상태 (선택)")

            HStack(spacing: 6) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Button {
                        selectedReadingStatus = selectedReadingStatus == status ? nil : status
                    } label: {
                        let isSelected = selectedReadingStatus == status

                        Text(status.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(isSelected ? status.badgeBackgroundColor : Color("Surface"))
                            .foregroundStyle(isSelected ? status.badgeForegroundColor : Color("TextPrimary"))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? status.badgeForegroundColor.opacity(0.35) : Color("TextMuted").opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("이 책, 어땠나요? (선택)")

                Spacer()

                if rating > 0 {
                    Button("초기화") {
                        rating = 0
                    }
                    .font(.caption)
                    .foregroundStyle(Color("TextMuted"))
                }
            }

            StarRatingView(rating: rating, isInteractive: true, starSize: 30) { newRating in
                rating = newRating
            }
        }
    }

    private var readingPeriodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("읽은 기간 (선택)")

            Button {
                isShowingReadingPeriodPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color("Primary"))

                    Text(BookMateDateFormatter.displayString(from: startDate))
                        .foregroundStyle(startDate == nil ? Color("TextMuted") : Color("TextPrimary"))

                    Text("~")
                        .foregroundStyle(Color("TextMuted"))

                    Text(BookMateDateFormatter.displayString(from: endDate))
                        .foregroundStyle(endDate == nil ? Color("TextMuted") : Color("TextPrimary"))

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color("TextMuted"))
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color("Surface"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("TextMuted").opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("나만의 감상평 (선택)")

            ZStack(alignment: .topLeading) {
                if reviewText.isEmpty {
                    Text("이 책을 읽고 남기고 싶은 느낌을 적어보세요.")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextMuted").opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                }

                TextEditor(text: $reviewText)
                    .focused($isReviewFocused)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .frame(minHeight: 132)
            }
            .background(Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("TextMuted").opacity(0.15), lineWidth: 1)
            )
        }
    }

    private var reviewPublicSection: some View {
        Toggle(isOn: $isReviewPublic) {
            VStack(alignment: .leading, spacing: 4) {
                Text("리뷰 공개")
                    .font(.headline)
                    .foregroundStyle(Color("TextMuted"))

                Text("공개하면 다른 사용자가 이 책의 리뷰를 볼 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextMuted"))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color("Primary")))
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("저장하기")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color("PrimaryButtonText"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("Primary"))
                .clipShape(Capsule())
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color("TextMuted"))
    }

    private func save() {
        isReviewFocused = false

        let trimmedReview = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = BookEditValues(
            category: selectedCategory,
            rating: rating > 0 ? rating : nil,
            review: trimmedReview.isEmpty ? nil : trimmedReview,
            isReviewPublic: isReviewPublic,
            readingStatus: selectedReadingStatus,
            startDate: BookMateDateFormatter.apiString(from: startDate),
            endDate: BookMateDateFormatter.apiString(from: endDate)
        )

        onSave(values)
        dismiss()
    }
}

#Preview {
    BookEditSheet(book: Book.dummyBooks[0]) { _ in }
}
