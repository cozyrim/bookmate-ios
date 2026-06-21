//
//  AuthModels.swift
//  BookMate
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
    let roomTheme: String?
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
    let roomTheme: String?
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
            isPublic: isPublic,
            roomTheme: roomTheme
        )
    }
}

struct ProfileImageUploadResponse: Decodable {
    let profileImageUrl: String
}

struct NicknameSuggestionResponse: Decodable {
    let nickname: String
}

struct EmailAvailabilityResponse: Decodable {
    let email: String
    let available: Bool
    let message: String
}

struct NicknameAvailabilityResponse: Decodable {
    let nickname: String
    let available: Bool
    let message: String
}

enum AuthValidation {
    static let nicknameMaxLength = 8
    static let nicknameRuleMessage = "닉네임은 8자 이하, 한글/영문/숫자만 사용할 수 있어요."
    static let passwordRuleMessage = "비밀번호는 8자 이상, 소문자, 숫자, 특수문자를 각각 1개 이상 포함해야 해요."

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func normalizedNickname(_ nickname: String) -> String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValidEmail(_ email: String) -> Bool {
        let normalized = normalizedEmail(email)
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return normalized.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    static func emailHelperText(_ email: String) -> String {
        let normalized = normalizedEmail(email)
        if normalized.isEmpty { return "이메일을 입력해주세요." }
        if !isValidEmail(normalized) { return "올바른 이메일 형식으로 입력해주세요." }
        return "이메일 중복 확인을 해주세요."
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8 &&
        password.range(of: #"[a-z]"#, options: .regularExpression) != nil &&
        password.range(of: #"\d"#, options: .regularExpression) != nil &&
        password.range(of: #"[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?`~]"#, options: .regularExpression) != nil &&
        password.range(of: #"\s"#, options: .regularExpression) == nil
    }

    static func passwordHelperText(_ password: String) -> String {
        if password.isEmpty { return passwordRuleMessage }
        return isValidPassword(password) ? "사용할 수 있는 비밀번호예요." : passwordRuleMessage
    }

    static func passwordConfirmHelperText(password: String, confirm: String) -> String {
        if confirm.isEmpty { return "비밀번호를 한 번 더 입력해주세요." }
        return password == confirm ? "비밀번호가 일치해요." : "비밀번호가 일치하지 않아요."
    }

    static func isValidNickname(_ nickname: String) -> Bool {
        let normalized = normalizedNickname(nickname)
        guard !normalized.isEmpty else { return false }
        guard normalized.count <= nicknameMaxLength else { return false }
        return normalized.range(of: #"^[가-힣A-Za-z0-9]+$"#, options: .regularExpression) != nil
    }

    static func nicknameHelperText(_ nickname: String) -> String {
        let normalized = normalizedNickname(nickname)
        if normalized.isEmpty { return "닉네임을 입력해주세요." }
        if normalized.count > nicknameMaxLength { return "닉네임은 8자 이하로 입력해주세요." }
        if !isValidNickname(normalized) { return nicknameRuleMessage }
        return "닉네임 중복 확인을 해주세요."
    }
}
