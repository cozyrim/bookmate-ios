//
//  ShelfBook.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/12/26.
//

import Foundation

struct ShelfBook: Identifiable {
    let id: String
    let ownerId: String
    let bookId: UUID
    var progress: Double
    var status: ReadingStatus
    var isPublic: Bool
    var createdAt: Date
    var updatedAt: Date
}

enum ReadingStatus: String, CaseIterable {
    case reading
    case completed
    case paused
    case wantToRead
    
    var displayName: String {
        switch self {
        case .wantToRead: return "읽고 싶어요"
        case .reading:    return "읽는 중"
        case .paused:   return "중단 됨"
        case .completed:    return "완독"
        }
    }
}

extension ShelfBook {
    static let sampleShelfBooks: [ShelfBook] = [
        ShelfBook(
            id: "shelf-siddhartha",
            ownerId: "sample-user",
            bookId: Book.dummyBooks[0].id,
            progress: 0.65,
            status: .reading,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        ShelfBook(
            id: "shelf-unbearable-lightness",
            ownerId: "sample-user",
            bookId: Book.dummyBooks[1].id,
            progress: 0.12,
            status: .reading,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        ShelfBook(
            id: "shelf-romantic-love",
            ownerId: "sample-user",
            bookId: Book.dummyBooks[2].id,
            progress: 0.49,
            status: .reading,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
