//
//  MiniRoomBookshelfView.swift
//  BookMate
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct MiniRoomBookshelfView: View {
    @Environment(\.colorScheme) private var colorScheme

    let books: [Book]
    let onBookTap: (Book) -> Void

    @State private var currentPage: Int? = 0

    private let slotTemplates = MiniRoomBookSlotTemplate.defaultSlots

    private var booksPerPage: Int {
        slotTemplates.count
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(books.count) / Double(booksPerPage))))
    }

    private var selectedPage: Int {
        min(max(currentPage ?? 0, 0), totalPages - 1)
    }

    private var controlForeground: Color {
        colorScheme == .dark ? Color("LightButtonText") : Color("PrimaryDeep")
    }

    private var emptyStateForeground: Color {
        colorScheme == .dark ? Color("TextPrimary").opacity(0.9) : Color("PrimaryDeep")
    }

    private var emptyStateBackground: AnyShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color("SurfaceElevated").opacity(0.76))
        }

        return AnyShapeStyle(Color("Surface").opacity(0.84))
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                bookPager(in: size)

                if books.isEmpty {
                    emptyState
                        .position(x: size.width * 0.54, y: size.height * 0.56)
                }

                if totalPages > 1 {
                    shelfPageHint
                        .position(x: size.width * 0.54, y: size.height * 0.82)
                }
            }
            .onChange(of: books.count) { _, _ in
                currentPage = selectedPage
            }
            .onAppear {
                currentPage = selectedPage
                PerformanceLogger.event("MiniRoomBookshelfAppear")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("미니룸 책장")
    }

    @ViewBuilder
    private func bookPager(in size: CGSize) -> some View {
        if totalPages <= 1 {
            bookPage(0, in: size)
                .frame(width: size.width, height: size.height)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<totalPages, id: \.self) { pageIndex in
                        bookPage(pageIndex, in: size)
                            .frame(width: size.width, height: size.height)
                            .id(pageIndex)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPage)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.32, dampingFraction: 0.84), value: currentPage)
            .onChange(of: currentPage) { _, page in
                PerformanceLogger.event("MiniRoomShelfPageChanged")
            }
        }
    }

    private func bookPage(_ pageIndex: Int, in size: CGSize) -> some View {
        let pageBooks = booksForPage(pageIndex)

        return ZStack {
            ForEach(Array(pageBooks.enumerated()), id: \.element.id) { slotIndex, book in
                let absoluteIndex = pageIndex * booksPerPage + slotIndex
                let slot = slotTemplates[slotIndex].resolve(in: size)

                Button {
                    PerformanceLogger.event("MiniRoomBookTapped")
                    onBookTap(book)
                } label: {
                    MiniRoomShelfBook(
                        title: book.title,
                        palette: spinePalette(for: absoluteIndex),
                        width: slot.width,
                        height: slot.height
                    )
                }
                .buttonStyle(.plain)
                .position(x: slot.centerX, y: slot.centerY)
                .zIndex(slot.zIndex)
                .accessibilityLabel("\(book.title) 책 상세 보기")
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private var emptyState: some View {
        VStack(spacing: 7) {
            Image(systemName: "books.vertical")
                .font(.title2)
            Text("읽은 책이 꽂혀요")
                .font(.caption.bold())
        }
        .foregroundStyle(emptyStateForeground)
        .padding(12)
        .background(emptyStateBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("Border").opacity(0.18), lineWidth: 1)
        }
    }

    private var shelfPageHint: some View {
        HStack(spacing: 9) {
            Button {
                currentPage = max(0, selectedPage - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
            }
            .disabled(selectedPage == 0)

            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { page in
                    Circle()
                        .fill(page == selectedPage ? controlForeground.opacity(0.86) : controlForeground.opacity(0.28))
                        .frame(width: page == selectedPage ? 8 : 5, height: page == selectedPage ? 8 : 5)
                }
            }
            .frame(minWidth: 38)

            Button {
                currentPage = min(totalPages - 1, selectedPage + 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
            }
            .disabled(selectedPage >= totalPages - 1)
        }
        .foregroundStyle(controlForeground.opacity(0.86))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.74))
                .shadow(color: Color("Shadow").opacity(0.10), radius: 8, y: 3)
        )
        .buttonStyle(.plain)
        .accessibilityLabel("책장이 여러 페이지입니다. 좌우로 넘길 수 있어요.")
    }

    private func booksForPage(_ pageIndex: Int) -> [Book] {
        guard !books.isEmpty else { return [] }

        let safePage = min(pageIndex, totalPages - 1)
        let startIndex = safePage * booksPerPage
        let endIndex = min(startIndex + booksPerPage, books.count)
        return Array(books[startIndex..<endIndex])
    }

    private func spinePalette(for index: Int) -> MiniRoomBookPalette {
        [
            MiniRoomBookPalette(base: Color(red: 238/255, green: 218/255, blue: 184/255), edge: Color(red: 172/255, green: 124/255, blue: 82/255), accent: Color(red: 184/255, green: 135/255, blue: 82/255)),
            MiniRoomBookPalette(base: Color(red: 177/255, green: 148/255, blue: 166/255), edge: Color(red: 116/255, green: 83/255, blue: 104/255), accent: Color(red: 136/255, green: 96/255, blue: 116/255)),
            MiniRoomBookPalette(base: Color(red: 221/255, green: 174/255, blue: 88/255), edge: Color(red: 146/255, green: 98/255, blue: 44/255), accent: Color(red: 164/255, green: 112/255, blue: 52/255)),
            MiniRoomBookPalette(base: Color(red: 100/255, green: 137/255, blue: 141/255), edge: Color(red: 52/255, green: 86/255, blue: 91/255), accent: Color(red: 70/255, green: 100/255, blue: 106/255)),
            MiniRoomBookPalette(base: Color(red: 224/255, green: 147/255, blue: 125/255), edge: Color(red: 150/255, green: 84/255, blue: 70/255), accent: Color(red: 172/255, green: 96/255, blue: 80/255)),
            MiniRoomBookPalette(base: Color(red: 151/255, green: 168/255, blue: 112/255), edge: Color(red: 88/255, green: 105/255, blue: 64/255), accent: Color(red: 108/255, green: 126/255, blue: 76/255)),
            MiniRoomBookPalette(base: Color(red: 190/255, green: 180/255, blue: 148/255), edge: Color(red: 116/255, green: 107/255, blue: 82/255), accent: Color(red: 132/255, green: 121/255, blue: 92/255)),
            MiniRoomBookPalette(base: Color(red: 129/255, green: 108/255, blue: 91/255), edge: Color(red: 80/255, green: 60/255, blue: 48/255), accent: Color(red: 96/255, green: 72/255, blue: 56/255))
        ][index % 8]
    }
}

private struct MiniRoomBookPalette {
    let base: Color
    let edge: Color
    let accent: Color
}

private struct MiniRoomBookSlotTemplate {
    let x: CGFloat
    let baselineY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let zIndex: Double

    static let defaultSlots: [MiniRoomBookSlotTemplate] = [
        MiniRoomBookSlotTemplate(x: 0.300, baselineY: 0.430, width: 0.074, height: 0.132, zIndex: 0),
        MiniRoomBookSlotTemplate(x: 0.388, baselineY: 0.430, width: 0.078, height: 0.145, zIndex: 1),
        MiniRoomBookSlotTemplate(x: 0.480, baselineY: 0.430, width: 0.076, height: 0.137, zIndex: 2),
        MiniRoomBookSlotTemplate(x: 0.572, baselineY: 0.430, width: 0.078, height: 0.148, zIndex: 3),
        MiniRoomBookSlotTemplate(x: 0.664, baselineY: 0.430, width: 0.076, height: 0.139, zIndex: 4),
        MiniRoomBookSlotTemplate(x: 0.756, baselineY: 0.430, width: 0.078, height: 0.146, zIndex: 5),

        MiniRoomBookSlotTemplate(x: 0.300, baselineY: 0.577, width: 0.076, height: 0.132, zIndex: 6),
        MiniRoomBookSlotTemplate(x: 0.388, baselineY: 0.577, width: 0.078, height: 0.145, zIndex: 7),
        MiniRoomBookSlotTemplate(x: 0.480, baselineY: 0.577, width: 0.076, height: 0.136, zIndex: 8),
        MiniRoomBookSlotTemplate(x: 0.572, baselineY: 0.577, width: 0.078, height: 0.147, zIndex: 9),
        MiniRoomBookSlotTemplate(x: 0.664, baselineY: 0.577, width: 0.076, height: 0.138, zIndex: 10),
        MiniRoomBookSlotTemplate(x: 0.756, baselineY: 0.577, width: 0.078, height: 0.146, zIndex: 11),

        MiniRoomBookSlotTemplate(x: 0.300, baselineY: 0.738, width: 0.076, height: 0.128, zIndex: 12),
        MiniRoomBookSlotTemplate(x: 0.388, baselineY: 0.738, width: 0.078, height: 0.141, zIndex: 13),
        MiniRoomBookSlotTemplate(x: 0.480, baselineY: 0.738, width: 0.076, height: 0.132, zIndex: 14),
        MiniRoomBookSlotTemplate(x: 0.572, baselineY: 0.738, width: 0.078, height: 0.143, zIndex: 15),
        MiniRoomBookSlotTemplate(x: 0.664, baselineY: 0.738, width: 0.076, height: 0.134, zIndex: 16),
        MiniRoomBookSlotTemplate(x: 0.756, baselineY: 0.738, width: 0.078, height: 0.141, zIndex: 17)
    ]

    func resolve(in size: CGSize) -> MiniRoomBookSlot {
        let resolvedHeight = height * size.height

        return MiniRoomBookSlot(
            centerX: x * size.width,
            baselineY: baselineY * size.height,
            centerY: baselineY * size.height - resolvedHeight / 2,
            width: width * size.width,
            height: resolvedHeight,
            zIndex: zIndex
        )
    }
}

private struct MiniRoomBookSlot {
    let centerX: CGFloat
    let baselineY: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let zIndex: Double
}

private struct MiniRoomShelfBook: View {
    let title: String
    let palette: MiniRoomBookPalette
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(3, width * 0.12))
                .fill(
                    LinearGradient(
                        colors: [
                            palette.base.opacity(0.95),
                            palette.base,
                            palette.edge.opacity(0.84)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: max(1, width * 0.12))
                }
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(width: max(1, width * 0.11))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: max(3, width * 0.12))
                        .stroke(palette.edge.opacity(0.42), lineWidth: 0.8)
                }

            spineDecoration

            VerticalBookTitle(title: title, width: width * 0.9, height: height * 0.84)
                .padding(.top, height * 0.04)
        }
        .frame(width: width, height: height)
        .shadow(color: Color("Shadow").opacity(0.13), radius: 2, y: 1)
    }

    private var spineDecoration: some View {
        VStack {
            Capsule()
                .fill(Color.white.opacity(0.24))
                .frame(width: width * 0.34, height: max(1, height * 0.012))

            Spacer()

            RoundedRectangle(cornerRadius: 1.5)
                .fill(palette.accent.opacity(0.32))
                .frame(width: width * 0.18, height: height * 0.08)
                .padding(.bottom, height * 0.04)
        }
        .padding(.top, height * 0.08)
    }
}

private struct VerticalBookTitle: View {
    let title: String
    let width: CGFloat
    let height: CGFloat

    private var rawCharacters: [String] {
        let compact = title
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        return compact.isEmpty ? ["책"] : compact.map { String($0) }
    }

    private var characters: [String] {
        let maxCount = 14

        guard rawCharacters.count > maxCount else {
            return rawCharacters
        }

        return Array(rawCharacters.prefix(maxCount - 1)) + ["..."]
    }

    private var rowHeight: CGFloat {
        max(1, height / CGFloat(max(maxRows, 1)))
    }

    private var characterFrameWidth: CGFloat {
        max(1, (width - columnSpacing) / CGFloat(titleColumns.count))
    }

    private var fontSize: CGFloat {
        let widthLimit = characterFrameWidth * 0.78
        let heightLimit = rowHeight * 0.7
        return min(11.5, max(6.2, min(widthLimit, heightLimit)))
    }

    private var titleColumns: [[String]] {
        guard characters.count > 7 else { return [characters] }

        let firstColumnCount = Int(ceil(Double(characters.count) / 2.0))
        let firstColumn = Array(characters.prefix(firstColumnCount))
        let secondColumn = Array(characters.dropFirst(firstColumnCount))
        return [firstColumn, secondColumn].filter { !$0.isEmpty }
    }

    private var maxRows: Int {
        titleColumns.map(\.count).max() ?? characters.count
    }

    private var columnSpacing: CGFloat {
        titleColumns.count > 1 ? max(1, width * 0.08) : 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: columnSpacing) {
            ForEach(Array(titleColumns.enumerated()), id: \.offset) { _, column in
                Text(column.joined(separator: "\n"))
                    .font(.system(size: fontSize, weight: .black))
                    .foregroundStyle(Color(red: 0.13, green: 0.10, blue: 0.08).opacity(0.82))
                    .lineLimit(column.count)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.white.opacity(0.35), radius: 0.35, y: 0.2)
                    .frame(width: characterFrameWidth, height: height, alignment: .center)
            }
        }
        .frame(width: width, height: height, alignment: .center)
        .allowsHitTesting(false)
    }
}
