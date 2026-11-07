import SwiftUI

struct HomeReadingCarousel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    let books: [Book]
    let onOpen: (Book) -> Void
    let onMore: (Book) -> Void

    @ScaledMetric(relativeTo: .caption2) private var progressHeight: CGFloat = 28

    @State private var selectedID: Book.ID?
    @State private var scrollOffset: CGFloat = 0

    private var bookIDs: [Book.ID] { books.map(\.id) }

    private var selectedIndex: Int {
        books.firstIndex { $0.id == selectedID } ?? 0
    }

    var body: some View {
        VStack(spacing: 4) {
            if let selectedBook = books.first(where: { $0.id == selectedID }) ?? books.first {
                coverShelf
                GeometryReader { geometry in
                    BookReadingProgress(progress: selectedBook.progress, status: selectedBook.readingStatus ?? .reading)
                        .frame(width: min(geometry.size.width * 0.56, 168) * 0.77)
                        .frame(maxWidth: .infinity)
                        .offset(x: reduceMotion ? 0 : -geometry.size.width * 0.09)
                        .accessibilityIdentifier("home.reading.progress")
                }
                .frame(height: max(progressHeight, 44))
                .overlay(alignment: .trailing) {
                    Button {
                        onMore(selectedBook)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.headline)
                            .foregroundStyle(Color("TextSecondary"))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(selectedBook.title) 메뉴")
                    .accessibilityIdentifier("home.reading.menu")
                }
                if books.count > 1 {
                    pageControls
                }
            }
        }
        .onChange(of: bookIDs, initial: true) { _, ids in
            if let selectedID, ids.contains(selectedID) { return }
            selectedID = ids.first
        }
    }

    private var coverShelf: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let coverSize = min(width * 0.56, 168)
            let usesReducedMotion = reduceMotion
            let step = usesReducedMotion ? coverSize : coverSize * 0.49
            let inset = max(0, (width - step) / 2)
            let isRightToLeft = layoutDirection == .rightToLeft
            let direction: CGFloat = isRightToLeft ? -1 : 1
            let position = scrollOffset / max(step, 1)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                        coverButton(book: book, index: index, size: coverSize, step: step,
                                    height: geometry.size.height, position: position,
                                    direction: direction, reducedMotion: usesReducedMotion)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(books.count == 1)
            .contentMargins(.horizontal, inset, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .center))
            .scrollPosition(id: $selectedID, anchor: .center)
            .onScrollGeometryChange(for: CGFloat.self) { scroll in
                if isRightToLeft {
                    return scroll.contentSize.width - scroll.containerSize.width
                        + scroll.contentInsets.trailing - scroll.contentOffset.x
                }
                return scroll.contentOffset.x + scroll.contentInsets.leading
            } action: { _, offset in
                scrollOffset = offset
            }
            .offset(x: usesReducedMotion ? 0 : -width * 0.09)
            .accessibilityIdentifier("home.reading.shelf")
        }
        .frame(height: 224)
    }

    private func coverButton(book: Book, index: Int, size: CGFloat, step: CGFloat,
                             height: CGFloat, position: CGFloat, direction: CGFloat,
                             reducedMotion: Bool) -> some View {
        let isSelected = index == selectedIndex
        let distance: CGFloat = (CGFloat(index) - position) * direction
        let depth: CGFloat = min(abs(distance), 2)
        let offset: CGFloat = reducedMotion ? 0 : coverOffset(distance: distance, step: step)
        let scale: CGFloat = reducedMotion ? 1 : 1 - depth * 0.12
        let angle: Double = reducedMotion ? 0 : Double(max(-28, min(28, -distance * 14)))
        let opacity: Double = reducedMotion ? 1 : Double(1 - depth * 0.09)

        return Button {
            if isSelected { onOpen(book) } else { select(book.id) }
        } label: {
            BookCoverCell(imageName: book.imageName, width: size, trailingPadding: 0,
                          showsBackground: false, coverCornerRadius: 8)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(book.title), \(book.author)")
        .accessibilityHint(isSelected ? "책 상세 열기" : "이 책 선택")
        .accessibilityIdentifier("home.reading.cover.\(book.id)")
        .frame(width: step, height: height)
        .scaleEffect(scale)
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .offset(x: offset)
        .opacity(opacity)
        .zIndex(-Double(abs(distance)))
    }

    private func coverOffset(distance: CGFloat, step: CGFloat) -> CGFloat {
        let magnitude = abs(distance)
        let visibleDistance = min(magnitude, 1) * 0.72 + max(0, magnitude - 1) * 0.32
        return (distance < 0 ? -1 : 1) * (visibleDistance - magnitude) * step
    }

    private var pageControls: some View {
        HStack(spacing: 8) {
            pageButton("이전 책", symbol: "chevron.backward", offset: -1)

            HStack(spacing: 6) {
                ForEach(books) { book in
                    let isSelected = book.id == (selectedID ?? books.first?.id)
                    Capsule()
                        .fill(isSelected ? Color("Primary") : Color("TextSecondary").opacity(0.32))
                        .frame(width: isSelected ? 15 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)

            Text("\(selectedIndex + 1)/\(books.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color("TextSecondary"))
                .accessibilityLabel("\(books.count)권 중 \(selectedIndex + 1)번째")
                .accessibilityIdentifier("home.reading.position")

            pageButton("다음 책", symbol: "chevron.forward", offset: 1)
        }
        .frame(maxWidth: .infinity)
    }

    private func pageButton(_ label: String, symbol: String, offset: Int) -> some View {
        let index = selectedIndex + offset
        let canMove = books.indices.contains(index)

        return Button {
            guard canMove else { return }
            select(books[index].id)
        } label: {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color("TextSecondary"))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .opacity(canMove ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!canMove)
        .accessibilityLabel(label)
    }

    private func select(_ id: Book.ID) {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.27)) {
            selectedID = id
        }
    }
}
