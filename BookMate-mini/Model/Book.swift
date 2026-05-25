//
//  Book.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import Foundation

struct Book: Identifiable, Hashable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let progress: Double
    
    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        imageName: String,
        progress: Double
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.imageName = imageName
        self.progress = progress
    }
}


extension Book {
    static let dummyBooks: [Book] = [
        Book(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "싯타르타",
            author: "헤르만 헤세",
            imageName: "싯타르타",
            progress: 0.65
        ),
        Book(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "참을 수 없는 존재의 가벼움",
            author: "밀란 쿤데라",
            imageName: "참을수",
            progress: 0.12
        ),
        Book(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "낭만적 연애와 그 후의 일상",
            author: "알랭 드 보통",
            imageName: "낭만적",
            progress: 0.49
        )
    ]
}
