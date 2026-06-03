//
//  DictionarySettingsView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct DictionarySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("suggestsSimilarWordsOnFailure") private var suggestsSimilarWordsOnFailure = true
    @AppStorage("remembersLastSelectedBook") private var remembersLastSelectedBook = true
    @AppStorage("showsExampleSentenceFieldByDefault") private var showsExampleSentenceFieldByDefault = true
    @AppStorage("savesRecentSearches") private var savesRecentSearches = true

    
    
    var body: some View {
        ZStack {
            Color.skyblue
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                SettingsScreenHeader(title: "사전 설정")
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        SettingsSectionCard(title: "검색 설정") {
                            SettingsValueRow(
                                iconName: "magnifyingglass",
                                title: "검색 방식",
                                value: "현재 방식 유지",
                                showsChevron: false
                            )
                            
                            SettingsDivider()
                            
                            SettingsToggleRow(
                                iconName: "sparkles",
                                title: "비슷한 단어 추천",
                                subtitle: "검색 결과가 없을 때 가까운 단어를 보여줘요.",
                                isOn: $suggestsSimilarWordsOnFailure
                            )
                        }
                        
                        SettingsSectionCard(title: "결과 표시") {
                            SettingsValueRow(
                                iconName: "list.bullet.rectangle",
                                title: "표시 방식",
                                value: "자세히 보기",
                                showsChevron: false
                            )
                        }
                        
                        SettingsSectionCard(title: "단어 저장") {
                            SettingsToggleRow(
                                iconName: "checkmark.square",
                                title: "마지막 책 기억",
                                subtitle: "직전에 선택한 책을 다음 저장 때 기본으로 보여줘요.",
                                isOn: $remembersLastSelectedBook
                            )
                            
                            SettingsDivider()
                            
                            SettingsToggleRow(
                                iconName: "text.alignleft",
                                title: "책 속 문장 입력란",
                                subtitle: "단어 저장 화면에서 문장 입력란을 항상 보여줘요.",
                                isOn: $showsExampleSentenceFieldByDefault
                            )
                        }
                        
                        SettingsSectionCard(title: "검색 기록") {
                            SettingsToggleRow(
                                iconName: "clock.arrow.circlepath",
                                title: "최근 검색어 저장",
                                subtitle: "최근 찾아본 단어를 다시 볼 수 있게 저장해요.",
                                isOn: $savesRecentSearches
                            )
                        }
                        
                        SettingsPrimaryButton(title: "저장하기") {
                            dismiss()
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        
    }
}

#Preview {
    DictionarySettingsView()
}
