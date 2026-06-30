//
//  APIEnvironment.swift
//  BookMate
//
//  Created by Codex on 6/17/26.
//

import Foundation

/// 앱이 백엔드 서버에 접속할 때 사용하는 공통 API 환경 설정이다.
enum APIEnvironment {
    private enum Environment: String {
        case local
        case staging
        case production
    }

    private static let simulatorHost = "127.0.0.1"
    private static let physicalDeviceHost = "192.168.0.45"
    private static let port = 8080

    private static var currentEnvironment: Environment {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "BOOKMATE_API_ENVIRONMENT") as? String,
              let environment = Environment(rawValue: value.lowercased()) else {
            return defaultEnvironment
        }

        return environment
    }

    private static var defaultEnvironment: Environment {
        #if DEBUG
        return .local
        #else
        return .production
        #endif
    }

    static var baseURL: URL {
        switch currentEnvironment {
        case .local:
            #if targetEnvironment(simulator)
            return URL(string: "http://\(simulatorHost):\(port)")!
            #else
            return URL(string: "http://\(physicalDeviceHost):\(port)")!
            #endif
        case .staging:
            return URL(string: "https://staging-api.bookmate.kr")!
        case .production:
            return URL(string: "https://api.bookmate.kr")!
        }
    }

    /// 서버가 로컬 주소로 내려준 이미지 URL을 현재 실행 환경에서 접근 가능한 주소로 바꾼다.
    static func displayURL(from string: String) -> URL? {
        guard var components = URLComponents(string: string) else {
            return nil
        }

        guard components.scheme == "http" else {
            return components.url
        }

        let host = components.host ?? ""
        let isLocalServer = host == simulatorHost
            || host == physicalDeviceHost
            || host == "localhost"
            || host == "::1"
            || host == "0.0.0.0"

        if isLocalServer {
            let baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components.scheme = baseComponents?.scheme
            components.host = baseComponents?.host
            components.port = baseComponents?.port
        } else if currentEnvironment != .local {
            components.scheme = "https"
        }

        return components.url
    }
}
