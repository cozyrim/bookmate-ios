//
//  APIEnvironment.swift
//  BookMate
//
//  Created by Codex on 6/17/26.
//

import Foundation

/// 앱이 백엔드 서버에 접속할 때 사용하는 공통 API 환경 설정이다.
enum APIEnvironment {
    private static let simulatorHost = "127.0.0.1"
    private static let physicalDeviceHost = "192.168.0.45"
    private static let port = 8080

    static var baseURL: URL {
        #if targetEnvironment(simulator)
        return URL(string: "http://\(simulatorHost):\(port)")!
        #else
        return URL(string: "http://\(physicalDeviceHost):\(port)")!
        #endif
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
        let isLocalServer = host == simulatorHost || host == "localhost" || host == "::1"

        if isLocalServer {
            let baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components.scheme = baseComponents?.scheme
            components.host = baseComponents?.host
            components.port = baseComponents?.port
        } else {
            components.scheme = "https"
        }

        return components.url
    }
}
