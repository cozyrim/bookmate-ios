//
//  Review.swift
//  BookMate
//
//  Created by 한채림 on 6/12/26.
//

import Foundation

struct Review: Identifiable, Hashable, Codable {
    let id: UUID
    let ownerId: UUID
    var ownerNickname: String
    var ownerProfileImageURL: String?
    let bookId: UUID
    var rating: Int
    var content: String
    var isPublic: Bool
    let createdAt: Date
    var updatedAt: Date
}

extension Review {
    static let sampleOwnerId = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!

    static let sampleReviews: [Review] = [
        Review(
            id: UUID(),
            ownerId: sampleOwnerId,
            ownerNickname: "책판다",
            ownerProfileImageURL: nil,
            bookId: Book.dummyBooks[0].id,
            rating: 4,
            content: "조용하지만 오래 남는 책이었다.",
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
