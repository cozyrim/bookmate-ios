//
//  DictionaryExampleLookupService.swift
//  BookMate
//
//  Created by 한채림 on 6/7/26.
//

import Foundation

final class DictionaryExampleLookupService {
    func fetchExample(word: String, targetCode: String) async -> String? {
        if let example = await fetchFromStdDict(targetCode: targetCode) {
            return example
        }
        
        if let example = await fetchFromAdditionalDictionary(word: word) {
            return example
        }
        return nil
    }
    
    private func fetchFromStdDict(targetCode: String) async -> String? {
        // 표준국어대사전 상세/용례 API가 있으면 여기서 조회
        return nil
    }
    
    private func fetchFromAdditionalDictionary(word: String) async -> String? {
        // 우리말샘 같은 추가 사전 API 조회
        return nil
    }
}
