//
//  PublicBookDetailView.swift
//  BookMate
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

struct PublicBookDetailView: View {
    let book: Book
    let ownerNickname: String
    
    private var ratingText: String {
            guard let rating = book.rating else { return "아직 별점 없음" }
            return "\(rating)점"
        }
    
    var body: some View {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        BookCoverCell(imageName: book.imageName, width: 150)

                        VStack(spacing: 8) {
                            Text(book.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)

                            Text(book.author)
                                .font(.callout)
                                .foregroundStyle(Color("TextSecondary"))

                            Text("\(ownerNickname)님의 책장")
                                .font(.caption)
                                .foregroundStyle(Color("TextMuted"))
                        }
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label(book.category, systemImage: "square.grid.2x2")
                                Spacer()
                                Label(ratingText, systemImage: "star.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(Color("TextSecondary"))

                            if let readingStatus = book.readingStatus {
                                Text(readingStatus.displayName)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color("Primary"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("Primary").opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("감상평")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color("TextMuted"))

                                Text(book.review?.isEmpty == false ? book.review! : "아직 공개된 감상평이 없어요.")
                                    .font(.callout)
                                    .foregroundStyle(Color("TextSecondary"))
                                    .lineSpacing(4)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Surface"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("공개 책")
            .navigationBarTitleDisplayMode(.inline)
        }
}

