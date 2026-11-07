import SwiftUI

/// A shared floating control surface; reading content keeps its opaque, legible background.
struct BookMateGlassSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var radius: CGFloat = 24

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color("Surface"), in: .rect(cornerRadius: radius))
        } else if #available(iOS 26, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            content.background(.regularMaterial, in: .rect(cornerRadius: radius))
        }
    }
}
