import SwiftUI

struct ShelfBookCardView: View {
    let imageName: String
    let author: String
    let title: String
    let category: String
    let progress: Double
    let wordCount: Int
    let readingStatus: ReadingStatus
    let onTap: () -> Void
    let onMoreTap: () -> Void

    private let coverWidth: CGFloat = 140
    private let menuSize: CGFloat = 44
    private var coverHeight: CGFloat { coverWidth * 1.56 * 0.84 }

    private var authorLine: String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedCategory.isEmpty || trimmedCategory == "카테고리 선택"
            ? author : "\(author) · \(trimmedCategory)"
    }

    private var progressPercent: Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    private var accessibilityProgressText: String {
        readingStatus.showsReadingProgress ? ", \(progressPercent)% 읽음" : ""
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                BookCoverCell(imageName: imageName, width: coverWidth, trailingPadding: 0, coverAlignment: .bottomLeading)
                    .frame(height: coverHeight, alignment: .bottomLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("TextPrimary"))
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, menuSize + 4)
                    Text(authorLine)
                        .font(.caption2)
                        .foregroundStyle(Color("TextSecondary"))
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    ReadingStatusBadge(status: readingStatus)
                    Spacer(minLength: 0)
                    Text("\(wordCount) 단어")
                        .font(.caption2)
                        .foregroundStyle(Color("TextSecondary"))
                        .lineLimit(1)
                }

                if readingStatus.showsReadingProgress {
                    readingProgress
                } else {
                    // Keep the next row aligned even when a book has no progress bar.
                    readingProgress.hidden()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(author), \(wordCount) 단어, \(readingStatus.displayName)\(accessibilityProgressText)")
        .accessibilityHint("책 상세 화면으로 이동합니다.")
        .accessibilityAction(named: Text("책 메뉴")) { onMoreTap() }
        .overlay(alignment: .topTrailing) {
            Button(action: onMoreTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: menuSize, height: menuSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 책 메뉴")
            .padding(.top, coverHeight + 12)
        }
    }

    private var readingProgress: some View {
        VStack(spacing: 4) {
            ProgressView(value: min(max(progress, 0), 1)).tint(Color("Primary"))
            Text("\(progressPercent)% 읽음")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
                        .foregroundStyle(Color("TextPrimary"))
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
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text(authorLine)
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary"))
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
