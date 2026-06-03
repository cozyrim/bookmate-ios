//
//  AppBackgroundTheme.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

enum AppBackgroundTheme: String, CaseIterable, Identifiable {
    case skyblue
        case nature
        case peach
        case green
        case customPhoto
    
    var id: String { rawValue }
    
    static var presetThemes: [AppBackgroundTheme] {
            [.skyblue, .nature, .peach, .green]
        }
    
    var title: String {
        switch self {
        case .skyblue:
            return "스카이 블루"
        case .nature:
                    return "자연"
                case .peach:
                    return "피치"
                case .green:
                    return "그린"
        case .customPhoto:
            return "내 사진"
        }
    }
    
    var subtitle: String {
        switch self {
        case .skyblue:
            return "기본 북메이트 배경"
        case .nature:
                    return "책 읽기 좋은 자연 이미지"
                case .peach:
                    return "따뜻한 복숭아빛 배경"
                case .green:
                    return "차분한 초록빛 배경"
        case .customPhoto:
            return "직접 고른 사진 배경"
        }
    }
}
