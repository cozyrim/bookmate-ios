//
//  Word.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import Foundation

struct Word: Identifiable, Hashable {
    let id: UUID
    let text: String
    let meaning: String
    let partOfSpeech: String
    let exampleSentence: String?
    let targetCode: String
    let bookId: UUID
    
    init(
        id: UUID = UUID(),
        text: String,
        meaning: String,
        partOfSpeech: String,
        exampleSentence: String?,
        targetCode: String,
        bookId: UUID
    ) {
        self.id = id
        self.text = text
        self.meaning = meaning
        self.partOfSpeech = partOfSpeech
        self.exampleSentence = exampleSentence
        self.targetCode = targetCode
        self.bookId = bookId
    }
}



extension Word {
    static let sampleWords: [Word] = [
        Word(text: "사무치다", meaning: "마음 깊이 맺히어 잊혀지지 않다.", partOfSpeech: "동사", exampleSentence: "살을 에는 듯한 찬 바람이 뼈에 사무친다.", targetCode: "0", bookId: Book.dummyBooks[0].id),
        Word(text: "찰나", meaning: "어떤 일이나 사물 현상이 일어나는 바로 그 순간.", partOfSpeech: "명사", exampleSentence: "찰나의 순간에 모든 것이 바뀌었다.", targetCode: "0", bookId: Book.dummyBooks[1].id),
        Word(text: "애틋하다", meaning: "섭섭하고 안타까워 애가 타는 듯하다.", partOfSpeech: "형용사", exampleSentence: "오랜만에 만난 친구와의 짧은 이별이 애틋했다.", targetCode: "0", bookId: Book.dummyBooks[2].id)
    ]
}
