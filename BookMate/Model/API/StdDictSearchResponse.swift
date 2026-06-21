//
//  StdDictSearchResponse.swift
//  BookMate
//
//  Created by 한채림 on 5/18/26.
//

import Foundation

struct StdDictSearchResponse: Codable {
    let channel: StdDictChannel
}

struct StdDictChannel: Codable {
    let item: [StdDictItem]
}

struct StdDictItem: Codable {
    let targetCode: String
    let word: String
    let pos: String
    let sense: StdDictSense
    
    enum CodingKeys: String, CodingKey {
        case targetCode = "target_code"
        case word
        case pos
        case sense
    }
}

struct StdDictSense: Codable {
    let definition: String
}

