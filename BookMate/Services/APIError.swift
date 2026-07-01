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

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "로그인이 만료됐어요."
        case .invalidResponse:
            return "서버 응답을 읽지 못했어요."
        case .badStatusCode(let statusCode):
            return "서버 응답 코드 \(statusCode)"
        }
    }
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
            return "서버에 연결하지 못했어요. 로컬 서버가 켜져 있는지 확인해 주세요."
        }

        if let apiError = self as? APIError,
           case .unauthorized = apiError {
            return "로그인이 만료됐어요. 다시 로그인해 주세요."
        }

        if let apiError = self as? APIError,
           case .badStatusCode(let statusCode) = apiError {
            if statusCode >= 500 {
                return "서버에서 처리하지 못했어요. 서버 상태 코드 \(statusCode)"
            }

            return "요청을 처리하지 못했어요. 서버 상태 코드 \(statusCode)"
        }

        if self is APIError {
            return localizedDescription
        }

        return fallback
    }
}
