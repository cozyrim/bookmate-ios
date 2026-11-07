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
    private var coverHeight: CGFloat { coverWidth * 1.56 * 0.84 }
    private var authorLine: String {
        let value = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || value == "카테고리 선택" ? author : "\(author) · \(value)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        BookCoverCell(imageName: imageName, width: coverWidth, trailingPadding: 0, coverAlignment: .bottomLeading)
                            .frame(height: coverHeight, alignment: .bottomLeading)
                        BookReadingProgress(progress: progress, status: readingStatus)
                            .frame(width: coverWidth * 0.77)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("TextPrimary"))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(authorLine)
                            .font(.caption)
                            .foregroundStyle(Color("TextSecondary"))
                            .lineLimit(1)
                    }
                    ReadingStatusBadge(status: readingStatus)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(bookAccessibilityLabel)
            .accessibilityHint("책 상세 화면으로 이동합니다.")
            .accessibilityAction(named: Text("책 메뉴")) { onMoreTap() }
            ShelfBookActions(title: title, wordCount: wordCount, onMoreTap: onMoreTap)
        }
    }

    private var bookAccessibilityLabel: String {
        let progressText = readingStatus.showsReadingProgress ? ", \(Int((min(max(progress, 0), 1) * 100).rounded()))% 읽음" : ""
        return "\(title), \(author), \(wordCount) 단어, \(readingStatus.displayName)\(progressText)"
    }
}

struct ShelfBookListCardView: View {
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
        let value = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || value == "카테고리 선택" ? author : "\(author) · \(value)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        BookCoverCell(imageName: imageName, width: 100, trailingPadding: 0)
                        BookReadingProgress(progress: progress, status: readingStatus)
                    }
                    .frame(width: 77)
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title).font(.headline).foregroundStyle(Color("TextPrimary"))
                                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            Text(authorLine).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                        }
                        ReadingStatusBadge(status: readingStatus)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(bookAccessibilityLabel)
            .accessibilityHint("책 상세 화면으로 이동합니다.")
            .accessibilityAction(named: Text("책 메뉴")) { onMoreTap() }
            ShelfBookActions(title: title, wordCount: wordCount, onMoreTap: onMoreTap)
                .padding(.leading, 97)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private var bookAccessibilityLabel: String {
        let progressText = readingStatus.showsReadingProgress ? ", \(Int((min(max(progress, 0), 1) * 100).rounded()))% 읽음" : ""
        return "\(title), \(author), \(wordCount) 단어, \(readingStatus.displayName)\(progressText)"
    }
}

private struct ShelfBookActions: View {
    let title: String
    let wordCount: Int
    let onMoreTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Label("\(wordCount) 단어", systemImage: "bookmark")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))
            Spacer(minLength: 0)
            Button(action: onMoreTap) {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 책 메뉴")
        }
    }
}
