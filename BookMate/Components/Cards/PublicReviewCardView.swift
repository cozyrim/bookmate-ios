//
//  PublicReviewCardView.swift
//  BookMate
//
//  Created by 한채림 on 6/13/26.
//

import SwiftUI

struct PublicReviewCardView: View {
    let review: Review

    private var dateText: String {
            BookMateDateFormatter.reviewDisplayString(from: review.updatedAt)
        }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ProfileImageView(
                    imageName: "profileImage",
                    imageURLString: review.ownerProfileImageURL,
                    showsEditIcon: false,
                    size: 38
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(review.ownerNickname)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("TextPrimary"))

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= review.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(Color("Primary"))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(dateText)
                        .font(.caption2)
                        .foregroundStyle(Color("TextMuted"))

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color("TextMuted"))
                }
            }

            Text(review.content.isEmpty ? "작성된 리뷰 내용이 없어요." : review.content)
                .font(.callout)
                .foregroundStyle(Color("TextSecondary"))
                .lineSpacing(4)
                .lineLimit(2)
                .frame(minHeight: 42, alignment: .top)
        }
        .padding(18)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color("Shadow").opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
