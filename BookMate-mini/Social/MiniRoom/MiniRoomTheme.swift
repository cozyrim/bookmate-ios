//
//  MiniRoomTheme.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/14/26.
//

import SwiftUI

enum MiniRoomTheme: String {
    case basic = "room_bg_default"
    case pink = "room_bg_pink"
    case mint = "room_bg_mint"
    
    static func from(_ value: String?) -> MiniRoomTheme {
            guard let value,
                  let theme = MiniRoomTheme(rawValue: value),
                  value != "AppBackground" else {
                return .basic
            }

            return theme
        }
    
    var imageName: String {
            rawValue
        }
    
    var backgroundColor: Color {
            switch self {
            case .pink:
                return Color(red: 251/255, green: 228/255, blue: 228/255)
            case .mint:
                return Color(red: 230/255, green: 247/255, blue: 245/255)
            case .basic:
                return Color(red: 249/255, green: 244/255, blue: 236/255)
            }
        }
}
