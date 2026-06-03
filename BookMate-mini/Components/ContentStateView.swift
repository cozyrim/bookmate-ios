//
//  StateViews.swift
//  BookMate-mini
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
        VStack(spacing: 26) {
            ZStack {
                Circle()
                    .fill(Color("Peach").opacity(0.16))
                    .frame(width: 230, height: 230)
                    .blur(radius: 22)
                
                RoundedRectangle(cornerRadius: 42)
                                    .fill(Color.white.opacity(0.78))
                                    .frame(width: 130, height: 130)
                                    .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)

                                RoundedRectangle(cornerRadius: 28)
                                    .fill(type == .empty ? Color("Peach").opacity(0.12) : Color.red.opacity(0.08))
                                    .frame(width: 82, height: 82)

                                Image(systemName: iconName)
                                    .font(.system(size: 42, weight: .semibold))
                                    .foregroundStyle(type == .empty ? Color("Brown") : .red.opacity(0.8))
            }
            
            VStack(spacing: 12) {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)

                            Text(message)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color("Brown"))
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
                                .foregroundStyle(Color("Brown"))
                                .frame(width: 245, height: 64)
                                .background(Color("Peach"))
                                .clipShape(Capsule())
                                .shadow(color: Color("Peach").opacity(0.25), radius: 14, x: 0, y: 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
    }
}

#Preview("Empty") {
    ZStack {
        Color.skyblue.ignoresSafeArea()

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
        Color.skyblue.ignoresSafeArea()

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
