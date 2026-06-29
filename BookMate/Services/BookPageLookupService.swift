//
//  BookPageLookupService.swift
//  BookMate
//
//  Created by 한채림 on 6/7/26.
//

import Foundation

private struct GoogleBooksResponse: Decodable {
    let items: [GoogleBookItem]?
}

private struct GoogleBookItem: Decodable {
    let volumeInfo: GoogleBookVolumeInfo
}

private struct GoogleBookVolumeInfo: Decodable {
    let pageCount: Int?
}

final class BookPageLookupService {
    private let aladinBookLookupService = AladinBookLookupService()
    
    func fetchPageCount(isbn: String) async -> Int? {
        if let aladinPageCount = await aladinBookLookupService.fetchPageCount(isbn: isbn) {
            return aladinPageCount
        }
        
        return await fetchGoogleBooksPageCount(isbn: isbn)
    }
    
    private func fetchGoogleBooksPageCount(isbn: String) async -> Int? {
        let cleanISBN = isbn
            .split(separator: " ")
            .last
            .map(String.init) ?? isbn
        
        guard !cleanISBN.isEmpty else { return nil }
        
        print("쪽수 조회 원본 ISBN:", isbn)
        print("쪽수 조회 cleanISBN:", cleanISBN)
        
        
        guard !cleanISBN.isEmpty else {
            print("쪽수 조회 실패: ISBN이 비어 있음")
            return nil }
        
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "isbn:\(cleanISBN)")
        ]
        guard let url = components?.url else {
            print("쪽수 조회 실패: URL 생성 실패")
            return nil }
        
        guard let url = components?.url else { return nil }
        
        do {
            let request = URLRequest(url: url, timeoutInterval: APIClient.defaultTimeoutInterval)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            return response.items?
                .compactMap { $0.volumeInfo.pageCount }
                .first
        } catch {
            print("Google Books 쪽수 조회 실패:", error)
            return nil
        }
    }
}
