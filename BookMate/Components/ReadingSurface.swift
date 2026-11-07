import SwiftUI

enum ReadingStyle {
    static let cardRadius: CGFloat = 24
    static let fieldRadius: CGFloat = 18
    static let coverRadius: CGFloat = 8
}

/// Quiet reading/input surface; glass is reserved for floating controls.
struct ReadingSurface: ViewModifier {
    var radius: CGFloat = ReadingStyle.cardRadius
    func body(content: Content) -> some View {
        content
            .background(Color("AppBackground").opacity(0.7), in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color("Border").opacity(0.5), lineWidth: 0.75)
            }
    }
}
