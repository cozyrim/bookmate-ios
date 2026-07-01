//
//  KakaoLoginService.swift
//  BookMate
//
//  Created by 한채림 on 6/3/26.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth

//카카오 로그인 실행
//→ 카카오 accessToken 받기
//→ 그 accessToken을 문자열로 돌려주기

enum KakaoLoginError: Error {
    case missingAccessToken
}

final class KakaoLoginService {
    func login() async throws -> String {
        try await requestToken { completion in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
    }

    private func requestToken(
        _ startLogin: (@escaping (OAuthToken?, Error?) -> Void) -> Void
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let accessToken = oauthToken?.accessToken else {
                    continuation.resume(throwing: KakaoLoginError.missingAccessToken)
                    return
                }
                
                continuation.resume(returning: accessToken)
            }

            startLogin(completion)
        }
    }

    func unlink() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UserApi.shared.unlink { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume()
            }
        }
    }
}
