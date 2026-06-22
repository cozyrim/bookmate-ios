//
//  AppBackgroundTheme.swift
//  BookMate
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

enum AppBackgroundTheme: String, CaseIterable, Identifiable {
    case skyblue
    case softPink = "nature"
    case peach
    case green
    case customPhoto
    
    var id: String { rawValue }
    
    static var presetThemes: [AppBackgroundTheme] {
        [.skyblue, .softPink, .peach, .green]
    }
    
    var title: String {
        switch self {
        case .skyblue:
            return "스카이 블루"
        case .softPink:
            return "소프트 핑크"
        case .peach:
            return "크림 옐로우"
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
        case .softPink:
            return "연한 핑크빛으로 부드럽게 밝힌 배경"
        case .peach:
            return "은은한 하늘빛이 섞인 밝은 크림 배경"
        case .green:
            return "차분한 초록빛 배경"
        case .customPhoto:
            return "직접 고른 사진 배경"
        }
    }
}
