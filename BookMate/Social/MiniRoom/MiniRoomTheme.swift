//
//  MiniRoomTheme.swift
//  BookMate
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

enum MiniRoomTheme: String, CaseIterable, Identifiable {
    case basic = "room_bg_default"
    case dark = "room_bg_dark"
    case pink = "room_bg_pink"
    case mint = "room_bg_mint"

    var id: String { rawValue }

    static func from(_ value: String?) -> MiniRoomTheme {
        guard let value,
              let theme = MiniRoomTheme(rawValue: value),
              value != "AppBackground" else {
            return .basic
        }

        return theme
    }

    var title: String {
        switch self {
        case .basic:
            return "기본"
        case .dark:
            return "밤 조명"
        case .pink:
            return "핑크"
        case .mint:
            return "민트"
        }
    }

    var subtitle: String {
        switch self {
        case .basic:
            return "따뜻한 낮의 독서방"
        case .dark:
            return "스탠드 불빛이 은은한 밤"
        case .pink:
            return "부드러운 핑크 톤"
        case .mint:
            return "차분한 민트 톤"
        }
    }

    var imageName: String {
        rawValue
    }

    func sceneImageName(for colorScheme: ColorScheme) -> String {
        switch self {
        case .dark:
            return "MiniRoomLayeredRoomBackgroundDark"
        case .basic:
            return "MiniRoomLayeredRoomBackground"
        case .pink, .mint:
            return "MiniRoomLayeredRoomBackground"
        }
    }

    var sceneTintColor: Color {
        switch self {
        case .pink:
            return Color(red: 255/255, green: 174/255, blue: 202/255)
        case .mint:
            return Color(red: 128/255, green: 220/255, blue: 199/255)
        case .dark, .basic:
            return .clear
        }
    }

    var sceneTintOpacity: Double {
        switch self {
        case .pink:
            return 0.34
        case .mint:
            return 0.32
        case .dark, .basic:
            return 0
        }
    }

    var backgroundColor: Color {
        switch self {
        case .pink:
            return Color(red: 251/255, green: 228/255, blue: 228/255)
        case .mint:
            return Color(red: 230/255, green: 247/255, blue: 245/255)
        case .dark:
            return Color(red: 15/255, green: 18/255, blue: 29/255)
        case .basic:
            return Color(red: 249/255, green: 244/255, blue: 236/255)
        }
    }
}
