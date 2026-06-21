//
//  DarkModeSettingsView.swift
//  BookMate
//
//  Created by 한채림 on 6/3/26.
//

import SwiftUI

enum AppColorMode: String, CaseIterable {
    case system, light, dark
    
    var title: String {
        switch self {
        case .system: return "시스템 설정"
        case .light: return "라이트 모드"
        case .dark: return "다크 모드"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}


struct DarkModeSettingsView: View {
    @AppStorage("appColorMode") private var appColorMode = AppColorMode.system.rawValue
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack(spacing: 24) {
                SettingsScreenHeader(title: "다크 모드")
                
                SettingsSectionCard(title: "화면 표시") {
                    ForEach(AppColorMode.allCases, id: \.rawValue) { mode in
                        Button {
                            appColorMode = mode.rawValue
                        } label: {
                            SettingsValueRow(
                                iconName: mode == .dark ? "moon" : "sun.max",
                                title: mode.title,
                                value: appColorMode == mode.rawValue ? "선택됨" : "",
                                showsChevron: false
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if mode != AppColorMode.allCases.last {
                            SettingsDivider()
                        }
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    DarkModeSettingsView()
}
