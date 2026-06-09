//
//  SocialModels.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/10/26.
//

import Foundation

// 검색 결과로 받을 유저 정보를 담을 모델
struct PublicUserResponse: Decodable, Identifiable {
    let id: UUID
    let nickname: String
    let profileImageUrl: String?
}

struct PublicBookResponse: Decodable {
    let id: UUID
    let title: String
    let author: String
    let imageName: String
    let category: String?
    let progress: Double
    let totalPages: Int?
    let currentPage: Int?
    let rating: Int?
    let review: String?
    let readingStatus: String?
    let startDate: String?
    let endDate: String?
    
    // 네트워크 응답을 우리가 UI에서 쓰는 'Book' 모델로 바꿔줌
    func toBook() -> Book {
        Book(
            id: id,
            title: title,
            author: author,
            imageName: imageName,
            category: category ?? "카테고리 선택",
            progress: progress,
            totalPages: totalPages,
            currentPage: currentPage,
            rating: rating,
            review: review,
            readingStatus: readingStatus.flatMap { ReadingStatus(rawValue: $0) },
            startDate: startDate,
            endDate: endDate
        )
    }
}
