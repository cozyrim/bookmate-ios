//
//  AppleLoginService.swift
//  BookMate
//
//  Created by Codex on 7/2/26.
//

import AuthenticationServices
import Foundation

struct AppleLoginCredentials {
    let userIdentifier: String
    let identityToken: String
    let authorizationCode: String?
    let email: String?
    let fullName: String?
}

enum AppleLoginError: LocalizedError {
    case invalidCredential
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Apple 로그인 정보를 확인할 수 없습니다."
        case .missingIdentityToken:
            return "Apple 로그인 토큰을 확인할 수 없습니다."
        }
    }
}

final class AppleLoginService {
    func credentials(from authorization: ASAuthorization) throws -> AppleLoginCredentials {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleLoginError.invalidCredential
        }

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AppleLoginError.missingIdentityToken
        }

        let authorizationCode = credential.authorizationCode.flatMap {
            String(data: $0, encoding: .utf8)
        }

        let fullName = credential.fullName.flatMap {
            PersonNameComponentsFormatter.localizedString(from: $0, style: .medium)
        }

        return AppleLoginCredentials(
            userIdentifier: credential.user,
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            email: credential.email,
            fullName: fullName
        )
    }
}
