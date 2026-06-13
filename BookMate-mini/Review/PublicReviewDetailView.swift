//
//  PublicReviewDetailView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/13/26.
//

import SwiftUI

struct PublicReviewDetailView: View {
    let review: Review
    let bookTitle: String

    var body: some View {
        ZStack {
                    Color("AppBackground")
                        .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 24) {
                                Text(bookTitle)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color("TextMuted"))

                                HStack(spacing: 12) {
                                    ProfileImageView(
                                        imageName: "profileImage",
                                        imageURLString: review.ownerProfileImageURL,
                                        showsEditIcon: false,
                                        size: 52
                                    )

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(review.ownerNickname)
                                            .font(.headline)

                                        Text(BookMateDateFormatter.reviewDisplayString(from: review.updatedAt))
                                            .font(.caption)
                                            .foregroundStyle(Color("TextMuted"))
                                    }

                                    Spacer()
                                }

                                HStack(spacing: 3) {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                                            .foregroundStyle(Color("Primary"))
                                    }
                                }

                                Text(review.content)
                                    .font(.body)
                                    .foregroundStyle(Color("TextPrimary"))
                                    .lineSpacing(6)
                            }
                            .padding(24)
                        }
                    }
                    .navigationTitle("리뷰")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
