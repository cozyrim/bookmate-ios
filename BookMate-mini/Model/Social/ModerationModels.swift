//
//  ModerationModels.swift
//  BookMate-mini
//
//  Created by Codex on 6/20/26.
//

import Foundation

enum ModerationTargetType: String, Codable {
    case guestbookMessage = "GUESTBOOK_MESSAGE"
    case publicProfile = "PUBLIC_PROFILE"
    case publicBookshelf = "PUBLIC_BOOKSHELF"
    case publicBook = "PUBLIC_BOOK"
    case publicReview = "PUBLIC_REVIEW"
}

enum ModerationReportReason: String, Codable, CaseIterable, Identifiable {
    case inappropriateLanguage = "INAPPROPRIATE_LANGUAGE"
    case harassment = "HARASSMENT"
    case spam = "SPAM"
    case personalInfo = "PERSONAL_INFO"
    case copyright = "COPYRIGHT"
    case other = "OTHER"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inappropriateLanguage:
            return "부적절한 표현"
        case .harassment:
            return "괴롭힘/비방"
        case .spam:
            return "스팸/광고"
        case .personalInfo:
            return "개인정보 노출"
        case .copyright:
            return "저작권 침해"
        case .other:
            return "기타"
        }
    }

    var description: String {
        switch self {
        case .inappropriateLanguage:
            return "욕설, 혐오 표현, 성적 표현 등"
        case .harassment:
            return "특정 사용자를 향한 공격이나 괴롭힘"
        case .spam:
            return "반복 홍보, 링크 도배, 무관한 내용"
        case .personalInfo:
            return "전화번호, 주소, 계정 등 민감 정보"
        case .copyright:
            return "권리 침해가 의심되는 콘텐츠"
        case .other:
            return "위 항목에 없는 문제"
        }
    }
}

enum ModerationReportStatus: String, Codable {
    case pending = "PENDING"
    case reviewed = "REVIEWED"
    case resolved = "RESOLVED"
    case rejected = "REJECTED"
}

enum ContentModerationContext: String, Codable {
    case guestbook = "GUESTBOOK"
    case profile = "PROFILE"
    case bookReview = "BOOK_REVIEW"
    case publicBookshelf = "PUBLIC_BOOKSHELF"
}

struct ModerationTarget: Identifiable, Equatable {
    let targetType: ModerationTargetType
    let targetId: String
    let targetUserId: UUID?
    let title: String
    let subtitle: String
    let snapshot: [String: String]

    var id: String {
        "\(targetType.rawValue)-\(targetId)"
    }
}

struct ModerationReportRequest: Encodable {
    let targetType: ModerationTargetType
    let targetId: String
    let targetUserId: String?
    let reason: ModerationReportReason
    let detail: String?
    let targetSnapshot: [String: String]?
}

struct ModerationReportEnvelope: Decodable {
    let report: ModerationReportResponse
    let reportCount: Int
    let shouldHideTarget: Bool
}

struct ModerationReportResponse: Decodable, Identifiable {
    let id: UUID
    let reporterUserId: UUID
    let targetType: ModerationTargetType
    let targetId: String
    let targetUserId: UUID?
    let reason: ModerationReportReason
    let detail: String?
    let status: ModerationReportStatus
    let createdAt: String
    let updatedAt: String
}

struct UserBlockResponse: Decodable, Identifiable {
    let id: UUID
    let blockerUserId: UUID
    let blockedUserId: UUID
    let createdAt: String
}

struct BlockUserRequest: Encodable {
    let blockedUserId: String
}

struct ContentCheckRequest: Encodable {
    let content: String
    let context: ContentModerationContext
}

struct ContentCheckResponse: Decodable {
    let allowed: Bool
    let reasons: [String]
}
