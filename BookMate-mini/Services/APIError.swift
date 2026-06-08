//
//  APIError.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

enum APIError: Error {
    case unauthorized         // 401 - 토큰 만료
    case invalidResponse      // 응답 형식이 이상할 때
    case badStatusCode(Int)   // 그 외 에러 상태코드
}
