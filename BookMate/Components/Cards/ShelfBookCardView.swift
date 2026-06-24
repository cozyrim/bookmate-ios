//
//  ShelfBookCardView.swift
//  BookMate
//
//  Created by 한채림 on 5/12/26.
//

import SwiftUI

struct ShelfBookCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let imageName: String
    let author: String
    let title: String
    let category: String
    let progress: Double
    let wordCount: Int
    let readingStatus: ReadingStatus

    let onTap: () -> Void
    let onMoreTap: () -> Void

    private var authorLine: String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCategory.isEmpty || trimmedCategory == "카테고리 선택" {
            return author
        }

        return "\(author) · \(trimmedCategory)"
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color("SurfaceElevated").opacity(0.94)
        : Color("Surface").opacity(0.96)
    }

    private var cardBorder: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color("Border").opacity(0.45)
    }

    private var cardShadow: Color {
        colorScheme == .dark
        ? Color.black.opacity(0.28)
        : Color("Shadow").opacity(0.055)
    }

    private var progressPercent: Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    private var accessibilityProgressText: String {
        readingStatus.showsReadingProgress ? ", \(progressPercent)% 읽음" : ""
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 9) {
                coverStack

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary").opacity(0.92))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Text(authorLine)
                        .font(.caption2)
                        .foregroundStyle(Color("TextSecondary").opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                HStack(spacing: 6) {
                    ReadingStatusBadge(status: readingStatus)

                    Spacer(minLength: 0)
                }

                if readingStatus.showsReadingProgress {
                    VStack(spacing: 4) {
                        ProgressView(value: min(max(progress, 0), 1))
                            .tint(Color("Primary"))

                        HStack {
                            Spacer(minLength: 0)

                            Text("\(progressPercent)% 읽음")
                                .font(.caption2)
                                .foregroundStyle(Color("TextPrimary").opacity(0.68))
                        }
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Button {
                onMoreTap()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color("TextPrimary").opacity(0.64))
                    .frame(width: 30, height: 30)
                    .background(cardBackground.opacity(0.82), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        }
        .shadow(
            color: cardShadow,
            radius: colorScheme == .dark ? 10 : 12,
            x: 0,
            y: colorScheme == .dark ? 6 : 5
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(author), \(wordCount) 단어, \(readingStatus.displayName)\(accessibilityProgressText)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("책 상세 화면으로 이동합니다.")
        .accessibilityAction(named: Text("책 메뉴")) {
            onMoreTap()
        }

    }

    private var coverStack: some View {
        HStack {
            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color("SurfaceSoft").opacity(colorScheme == .dark ? 0.42 : 0.78))
                    .frame(width: 126, height: 154)

                BookCoverCell(
                    imageName: imageName,
                    width: 112,
                    trailingPadding: 0,
                    showsBackground: false
                )
            }
            .overlay(alignment: .bottomTrailing) {
                wordCountBadge
                    .offset(x: 4, y: -5)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
        .padding(.bottom, 7)
    }

    private var wordCountBadge: some View {
        Text("\(wordCount) 단어")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color("Success").opacity(0.9))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color("SuccessSoft").opacity(0.98), in: Capsule())
            .shadow(color: Color("Shadow").opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct ShelfBookListCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let imageName: String
    let author: String
    let title: String
    let category: String
    let progress: Double
    let wordCount: Int
    let readingStatus: ReadingStatus

    let onTap: () -> Void
    let onMoreTap: () -> Void

    private var authorLine: String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCategory.isEmpty || trimmedCategory == "카테고리 선택" {
            return author
        }

        return "\(author) · \(trimmedCategory)"
    }

    private var cardBackground: Color {
        colorScheme == .dark
        ? Color("SurfaceElevated").opacity(0.94)
        : Color("Surface").opacity(0.96)
    }

    private var cardBorder: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color("Border").opacity(0.45)
    }

    private var progressPercent: Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    private var accessibilityProgressText: String {
        readingStatus.showsReadingProgress ? ", \(progressPercent)% 읽음" : ""
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            BookCoverCell(imageName: imageName, width: 82)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary").opacity(0.92))
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    Text("\(wordCount) 단어")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("Success").opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("SuccessSoft"), in: Capsule())

                    Button {
                        onMoreTap()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color("TextPrimary").opacity(0.65))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text(authorLine)
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary").opacity(0.82))
                    .lineLimit(1)

                ReadingStatusBadge(
                    status: readingStatus,
                    horizontalPadding: 10,
                    verticalPadding: 6
                )
                    .padding(.top, 8)

                if readingStatus.showsReadingProgress {
                    VStack(spacing: 4) {
                        ProgressView(value: min(max(progress, 0), 1))
                            .tint(Color("Primary"))

                        HStack {
                            Spacer(minLength: 0)
                            Text("\(progressPercent)% 읽음")
                                .font(.caption)
                                .foregroundStyle(Color("TextPrimary").opacity(0.7))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        }
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.28) : Color("Shadow").opacity(0.055),
            radius: colorScheme == .dark ? 10 : 12,
            x: 0,
            y: colorScheme == .dark ? 6 : 5
        )
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(author), \(wordCount) 단어, \(readingStatus.displayName)\(accessibilityProgressText)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("책 상세 화면으로 이동합니다.")
        .accessibilityAction(named: Text("책 메뉴")) {
            onMoreTap()
        }
    }
}

#Preview {
    ShelfBookCardView(imageName: Book.dummyBooks[0].imageName, author:Book.dummyBooks[0].author , title: Book.dummyBooks[0].title, category: "소설", progress: 0.65, wordCount: 12, readingStatus: .reading, onTap: {},
                      onMoreTap: {})
}
