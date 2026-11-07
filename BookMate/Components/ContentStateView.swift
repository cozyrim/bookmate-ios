//
//  StateViews.swift
//  BookMate
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI

struct ContentStateView: View {
    enum StateType {
            case empty
            case error
        }
    
    let type: StateType
        let iconName: String
        let title: String
        let message: String
        let buttonTitle: String?
        let buttonIconName: String?
        let buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: iconName)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(type == .empty ? Color("TextSecondary") : Color("Error"))
                .accessibilityHidden(true)
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("TextPrimary"))

                            Text(message)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color("TextSecondary"))
                                .lineSpacing(4)
                        }
            .padding(.horizontal, 34)
            
            if let buttonTitle, let buttonAction {
                            Button {
                                buttonAction()
                            } label: {
                                HStack(spacing: 10) {
                                    if let buttonIconName {
                                        Image(systemName: buttonIconName)
                                    }

                                    Text(buttonTitle)
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: 280, minHeight: 48)
                                .background(Color("Primary"))
//                                .foregroundStyle(Color("TextPrimary"))
                                .foregroundStyle(Color("PrimaryButtonText"))
                                
                                
                                
                                .clipShape(Capsule())
                                
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
    }
}

#Preview("Empty") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        ContentStateView(
            type: .empty,
            iconName: "book",
            title: "아직 저장한 단어가 없어요.",
            message: "지금 읽고 있는 책에서 모르는 단어를 검색해보세요.",
            buttonTitle: "단어 검색하기",
            buttonIconName: "magnifyingglass",
            buttonAction: {}
        )
    }
}

#Preview("Error") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        ContentStateView(
            type: .error,
            iconName: "exclamationmark.triangle",
            title: "단어를 불러오지 못했어요.",
            message: "네트워크 상태를 확인한 뒤 다시 시도해 주세요.",
            buttonTitle: "다시 시도하기",
            buttonIconName: "arrow.clockwise",
            buttonAction: {}
        )
    }
}
