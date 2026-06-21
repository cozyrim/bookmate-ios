//
//  StarRatingView.swift
//  BookMate
//
//  Created by 한채림 on 6/9/26.
//

import SwiftUI

/// 별점 표시 + 선택 컴포넌트
/// - isInteractive: true면 터치로 별점 변경 가능, false면 표시만
struct StarRatingView: View {
    let rating: Int          // 현재 별점 (0~5)
    var isInteractive: Bool = false
    var starSize: CGFloat = 22
    var onRatingChanged: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(
                        star <= rating
                            ? Color("Primary")
                            : Color("TextMuted").opacity(0.3)
                    )
                    .onTapGesture {
                        guard isInteractive else { return }
                        // 같은 별점 탭하면 0으로 초기화 (선택 해제)
                        onRatingChanged?(star == rating ? 0 : star)
                    }
                    .animation(.spring(duration: 0.2), value: rating)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 표시용
        StarRatingView(rating: 4)

        // 인터랙티브
        StarRatingView(rating: 3, isInteractive: true, starSize: 32) { newRating in
            print("별점: \(newRating)")
        }
    }
    .padding()
    .background(Color("AppBackground"))
}
