//
//  Quote.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

struct Quote: Identifiable, Hashable {
    let id: UUID
    let text: String // 구절 내용
    let page: Int?
    let memo: String? // 구절에 대한 내 메모
    let bookId: UUID // 어느 책에서 나온 구절인지
    
    init(
        id: UUID = UUID(),
        text: String,
        page: Int? = nil,
        memo: String? = nil,
        bookId: UUID
    ) {
        self.id = id
        self.text = text
        self.page = page
        self.memo = memo
        self.bookId = bookId
    }
}

extension Quote {
    static let sampleQuotes: [Quote] = [
        Quote(
            text: "우리는 모두 강을 건너야 한다. 그것이 삶이다.",
            page: 42,
            memo: "삶의 본질에 대한 통찰",
            bookId: Book.dummyBooks[0].id
        ),
        Quote(
            text: "가장 무거운 짐은 동시에 가장 충만한 삶의 이미지다.",
            page: 17,
            memo: nil,
            bookId: Book.dummyBooks[1].id
        )
    ]
}
