//
//  ProfileMenuItem.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import Foundation

enum ProfileRoute: Hashable {
    case editProfile // 프로필 수정 화면
    case accountManagement // 계정 관리 화면
    case notificationSettings // 알림 설정 화면
    case themeSettings // 화면 테마 설정 화면
    case appInfo // 앱 정보 화면
    case darkModeSettings // 다크 모드 화면
}


struct ProfileMenuItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    var route: ProfileRoute?
    var isDestructive: Bool = false
    var showChevron: Bool = true
}

