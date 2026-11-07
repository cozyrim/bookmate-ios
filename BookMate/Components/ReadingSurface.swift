import SwiftUI

/// Quiet reading/input surface; glass is reserved for floating controls.
struct ReadingSurface: ViewModifier {
    var radius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .background(Color("AppBackground").opacity(0.7), in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color("Border").opacity(0.5), lineWidth: 0.75)
            }
    }
}
