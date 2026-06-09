//
//  AuthModels.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import Foundation

struct AuthUser: Decodable, Identifiable { // 서버에서 로그인 성공 후 내려주는 user 부분의 모양, 현재 사용자 정보
    let id: UUID
    let email: String?
    let provider: String
    let nickname: String
    let profileImageUrl: String?
    let createdAt: String?
    let isPublic: Bool?
}

struct AuthResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let user: AuthUser
}

struct ProfileResponse: Decodable {
    let id: UUID
    let email: String?
    let provider: String
    let nickname: String
    let profileImageUrl: String?
    let createdAt: String?
    let togetherDays: Int
    let savedWordCount: Int
    let readBookCount: Int
    let isPublic: Bool
}

extension ProfileResponse {
    func toAuthUser() -> AuthUser {
        AuthUser(
            id: id,
            email: email,
            provider: provider,
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            createdAt: createdAt,
            isPublic: isPublic
        )
    }
}

struct ProfileImageUploadResponse: Decodable {
    let profileImageUrl: String
}
