//
//  AladinBookLookupService.swift
//  BookMate
//
//  Created by 한채림 on 6/7/26.
//

import Foundation

private struct AladinItemLookupResponse: Decodable {
    let item: [AladinBookItem]?
}

private struct AladinBookItem: Decodable {
    let description: String?
    let subInfo: AladinSubInfo?
}

private struct AladinSubInfo: Decodable {
    let itemPage: Int?
}

struct BookLookupMetadata {
    let pageCount: Int?
    let description: String?
}


enum AladinBookLookupError: Error {
    case missingAPIKey
        case invalidURL
        case invalidResponse
        case badStatusCode(Int)
}

final class AladinBookLookupService {
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String = AladinBookLookupService.defaultAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchPageCount(isbn: String) async -> Int? {
        let metadata = await fetchMetadata(isbn: isbn)
            return metadata?.pageCount
    }
    
    func fetchMetadata(isbn: String) async -> BookLookupMetadata? {
        let cleanISBN = isbn
            .split(separator: " ")
            .last
            .map(String.init) ?? isbn

        guard !cleanISBN.isEmpty else { return nil }
        guard !apiKey.isEmpty else { return nil }

        var components = URLComponents(string: "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx")
        components?.queryItems = [
            URLQueryItem(name: "ttbkey", value: apiKey),
            URLQueryItem(name: "itemIdType", value: "ISBN13"),
            URLQueryItem(name: "ItemId", value: cleanISBN),
            URLQueryItem(name: "output", value: "js"),
            URLQueryItem(name: "Version", value: "20131101")
        ]

        guard let url = components?.url else { return nil }

        do {
            let request = URLRequest(url: url, timeoutInterval: APIClient.defaultTimeoutInterval)
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                return nil
            }

            let decoded = try JSONDecoder().decode(AladinItemLookupResponse.self, from: data)
            let item = decoded.item?.first

            return BookLookupMetadata(
                pageCount: item?.subInfo?.itemPage,
                description: item?.description
            )
        } catch {
            return nil
        }
    }
    
    
    private static var defaultAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ALADIN_TTB_KEY") as? String else {
            return ""
        }
        
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "$(ALADIN_TTB_KEY)" else {
            return ""
        }
        
        return trimmedKey
    }
}
