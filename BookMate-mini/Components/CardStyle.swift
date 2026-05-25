//
//  CardStyle.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
