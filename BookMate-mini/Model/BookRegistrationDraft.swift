//
//  BookRegistrationDraft.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import Foundation

struct BookRegistrationDraft: Identifiable, Hashable {
    let id: String
    var title: String
    var author: String
    var publisher: String
    var contents: String
    var imageName: String
    var category: String
    var progress: Double = 0.0
    
    
    // init = 처음 만들 때 값 넣는 함수
//    self = 지금 만들어지는 자기 자신
//    init의 파라미터 = 밖에서 받아오는 재료
//    self.title = title = 받은 재료를 내 저장 칸에 넣기
    init(
        id: String = UUID().uuidString,
        title: String,
        author: String,
        publisher: String = "",
        contents: String = "",
        imageName: String = "책기본이미지",
        category: String = "카테고리 선택",
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.publisher = publisher
        self.contents = contents
        self.imageName = imageName
        self.category = category
        self.progress = progress
    }
    
    
    
    // 현재 Book은 서버 저장 후의 모델이기 때문에 카카오 검색 결과는 후보라서 Draft로 들고있음
    init(kakaoBook: KakaoBook) {
        self.id = kakaoBook.id
        self.title = kakaoBook.title
        self.author = kakaoBook.authors.joined(separator: ", ")
        self.publisher = kakaoBook.publisher
        self.contents = kakaoBook.contents
        self.imageName = kakaoBook.thumbnail.isEmpty ? "책기본이미지" : kakaoBook.thumbnail
        self.category = "카테고리 선택"
        self.progress = 0.0
    }
}
