import SwiftUI

private struct ShelfBookTitleBoundsKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

/// Reading progress belongs to the cover, in both grid and list presentations.
private struct CoverReadingProgress: View {
    let progress: Double
    let status: ReadingStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: min(max(progress, 0), 1)).tint(Color("Primary"))
            Text("\(Int((min(max(progress, 0), 1) * 100).rounded()))% 읽음")
                .font(.caption2)
                .foregroundStyle(Color("TextSecondary"))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 28, alignment: .top)
        .opacity(status.showsReadingProgress ? 1 : 0)
        .accessibilityHidden(!status.showsReadingProgress)
    }
}

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

    private var accessibilityProgressText: String {
        readingStatus.showsReadingProgress ? ", \(Int((min(max(progress, 0), 1) * 100).rounded()))% 읽음" : ""
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    BookCoverCell(imageName: imageName, width: coverWidth, trailingPadding: 0, coverAlignment: .bottomLeading)
                        .frame(height: coverHeight, alignment: .bottomLeading)
                    CoverReadingProgress(progress: progress, status: readingStatus)
                        .frame(width: coverWidth * 0.77)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 36)
                    .anchorPreference(key: ShelfBookTitleBoundsKey.self, value: .bounds) { $0 }
                Text(authorLine)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(readingStatus.displayName)
                        .foregroundStyle(Color("PrimaryDeep"))
                    Spacer(minLength: 0)
                    Text("\(wordCount) 단어").foregroundStyle(Color("TextSecondary"))
                }
                .font(.caption2)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(author), \(wordCount) 단어, \(readingStatus.displayName)\(accessibilityProgressText)")
        .accessibilityHint("책 상세 화면으로 이동합니다.")
        .accessibilityAction(named: Text("책 메뉴")) { onMoreTap() }
        .overlayPreferenceValue(ShelfBookTitleBoundsKey.self) { titleBounds in
            GeometryReader { geometry in
                if let titleBounds {
                    Button(action: onMoreTap) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color("TextSecondary"))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) 책 메뉴")
                    .position(x: geometry.size.width - 14, y: geometry[titleBounds].minY + 22)
                }
            }
        }
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

    private var accessibilityProgressText: String {
        readingStatus.showsReadingProgress ? ", \(Int((min(max(progress, 0), 1) * 100).rounded()))% 읽음" : ""
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    BookCoverCell(imageName: imageName, width: 100, trailingPadding: 0)
                    CoverReadingProgress(progress: progress, status: readingStatus)
                }
                .frame(width: 77)
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.headline).foregroundStyle(Color("TextPrimary"))
                        .lineLimit(2).padding(.trailing, 44)
                    Text(authorLine).font(.subheadline).foregroundStyle(Color("TextSecondary"))
                    Text(readingStatus.displayName).font(.caption).foregroundStyle(Color("PrimaryDeep"))
                    Text("저장한 단어 \(wordCount)개").font(.caption).foregroundStyle(Color("TextSecondary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                Image(systemName: "ellipsis").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 책 메뉴")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}
