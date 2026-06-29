//
//  APIError.swift
//  BookMate
//
//  Created by 한채림 on 6/9/26.
//

import Foundation

enum APIError: Error {
    case unauthorized         // 401 - 토큰 만료
    case invalidResponse      // 응답 형식이 이상할 때
    case badStatusCode(Int)   // 그 외 에러 상태코드
}

extension Error {
    var isNetworkTimeout: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut
    }

    var isConnectivityError: Bool {
        guard let urlError = self as? URLError else {
            return false
        }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
            return true
        default:
            return false
        }
    }

    func bookMateUserMessage(fallback: String) -> String {
        if isNetworkTimeout {
            return "응답 시간이 초과됐어요. 잠시 후 다시 시도해 주세요."
        }

        if isConnectivityError {
            return "인터넷 연결을 확인해 주세요."
        }

        if let apiError = self as? APIError,
           case .unauthorized = apiError {
            return "로그인이 만료됐어요. 다시 로그인해 주세요."
        }

        return fallback
    }
}
