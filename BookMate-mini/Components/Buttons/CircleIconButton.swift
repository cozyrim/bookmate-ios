//
//  CircleIconButton.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/5/26.
//

import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("TextPrimary"))
                .frame(width: 44, height: 44)
                .background(Color("Surface").opacity(0.92))
                .clipShape(Circle())
                .shadow(color: Color("Shadow").opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        CircleIconButton(systemName: "chevron.left") { }
        CircleIconButton(systemName: "xmark") { }
    }
    .padding()
    .background(Color("AppBackground"))
}
