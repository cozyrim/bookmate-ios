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
            .background(Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct PartOfSpeechBadge: View {
    let text: String
    var font: Font = .caption2
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.semibold)
            .foregroundStyle(Color("PrimaryDeep").opacity(0.76))
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Color("Primary").opacity(0.11), in: Capsule())
    }
}

struct ReadingStatusBadge: View {
    let status: ReadingStatus
    var font: Font = .caption2
    var fontWeight: Font.Weight = .medium
    var horizontalPadding: CGFloat = 9
    var verticalPadding: CGFloat = 5

    var body: some View {
        Text(status.displayName)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(status.badgeForegroundColor)
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(status.badgeBackgroundColor, in: Capsule())
    }
}

extension ReadingStatus {
    var badgeForegroundColor: Color {
        switch self {
        case .reading:
            return Color("PrimaryDeep")
        case .completed:
            return Color("Success")
        case .paused:
            return Color("Error")
        case .wantToRead:
            return Color("Warning")
        }
    }

    var badgeBackgroundColor: Color {
        switch self {
        case .reading:
            return Color("Primary").opacity(0.12)
        case .completed:
            return Color("SuccessSoft").opacity(0.78)
        case .paused:
            return Color("ErrorSoft").opacity(0.72)
        case .wantToRead:
            return Color("WarningSoft").opacity(0.78)
        }
    }
}
