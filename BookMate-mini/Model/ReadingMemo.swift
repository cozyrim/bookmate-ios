//
//  ReadingMemo.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

struct ReadingMemo: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: UUID
    let date: String // "2026-01-16"
    let page: Int?
    let text: String
    
    init(id: UUID = UUID(), bookId: UUID, date: String, page: Int? = nil, text: String) {
        self.id = id
        self.bookId = bookId
        self.date = date
        self.page = page
        self.text = text
    }
}
