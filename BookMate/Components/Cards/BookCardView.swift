//
//  WordCardView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import SwiftUI

struct BookCardView: View {
    let imageName: String
    let title: String
    let author: String
    let progress: Double
    let category: String
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
    
    
    var body: some View {
        HStack(spacing: 14) {
            BookCoverCell(imageName: imageName, width: 62)
//                .resizable()
//                .frame(width: 55, height: 77)
//                .clipShape(RoundedRectangle(cornerRadius: 18))
//                .padding(.trailing)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary").opacity(0.92))
                        .lineLimit(1)
                    
                    Spacer()
                    
//                    MoreOptionsMenu(
//                                            editTitle: "책 수정하기",
//                                            deleteTitle: "책 삭제하기",
//                                            moveTitle: nil,
//                                            onEdit:onEdit,
//                                            onDelete: onDelete
//                                            )
                    
                    Button {
                        onMoreTap()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color("TextPrimary").opacity(0.55))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                       
                }
                
                Text(authorLine)
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary").opacity(0.82))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ReadingStatusBadge(
                        status: readingStatus,
                        font: .caption2,
                        fontWeight: .semibold,
                        horizontalPadding: 8,
                        verticalPadding: 4
                    )

                    Spacer(minLength: 0)

                    Text("\(progressPercent)% 읽음")
                        .font(.caption)
                        .foregroundStyle(Color("TextPrimary").opacity(0.7))
                }

                ProgressView(value: min(max(progress, 0), 1))
                    .tint(Color("Primary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 124)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
        .padding(.top, 8)
        .padding(.horizontal,  24)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    BookCardView(imageName: "싯타르타", title: "싯타르타", author: "해르만헤세 / 고전소설", progress: 0.65, category: "소설", readingStatus: .reading, onTap: {},
                 onMoreTap: {})
}
