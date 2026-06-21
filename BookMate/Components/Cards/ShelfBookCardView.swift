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


    var body: some View {
        HStack {
            BookCoverCell(imageName: imageName, width: 82)

            VStack(alignment: .leading, spacing: 4) {
                HStack{
                    Text("\(title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary").opacity(0.92))

                    Spacer()

                        Text("\(wordCount) 단어")
                            .font(.caption2)
                            .foregroundStyle(Color("TextSecondary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color("SuccessSoft"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)

                        Button {
                            onMoreTap()
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color("TextPrimary").opacity(0.75))
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                }
                Text(authorLine)
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary").opacity(0.82))

                VStack(alignment: .leading){
                    HStack {
                        Text(readingStatus.displayName)
                            .font(.caption2)
                            .foregroundStyle(Color("PrimaryDeep"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color("Primary").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                            .font(.caption2)
//                                                        .foregroundStyle(Color("Success"))
//                                                        .padding(.horizontal, 8)
//                                                        .padding(.vertical, 6)
//                                                        .background(Color("SuccessSoft"))
//                                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    }
                    VStack(spacing: 4) {
                        ProgressView(value: progress)
                            .tint(Color("Primary"))

                        HStack {
                            Spacer()
                            Text("\(Int(progress * 100))% 읽음")
                                .font(.caption)
                                .foregroundStyle(Color("TextPrimary").opacity(0.7))
                        }
                    }

                }
                .padding(.top)
            }


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
            color: cardShadow,
            radius: colorScheme == .dark ? 10 : 12,
            x: 0,
            y: colorScheme == .dark ? 6 : 5
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }

    }

}

#Preview {
    ShelfBookCardView(imageName: Book.dummyBooks[0].imageName, author:Book.dummyBooks[0].author , title: Book.dummyBooks[0].title, category: "소설", progress: 0.65, wordCount: 12, readingStatus: .reading, onTap: {},
                      onMoreTap: {})
}
