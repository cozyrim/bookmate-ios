//
//  SaveButton.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct SaveButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            print("저장하기")
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bookmark")
                Text("저장하기")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("Primary"))
            .clipShape(Capsule())
        }
        .padding(.top, 8)
    }
}

#Preview {
    SaveButton {
        print("프리뷰 저장 버튼 탭")
    }
}
