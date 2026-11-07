import SwiftUI

/// A small outlined word notebook: letter, definition line, and binding.
struct VocabularyTabIcon: View {
    var body: some View {
        VocabularyNotebookShape()
            .stroke(style: StrokeStyle(lineWidth: 1.45, lineCap: .round, lineJoin: .round))
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}

private struct VocabularyNotebookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: CGRect(x: 2.5, y: 1, width: 15, height: 18), cornerSize: CGSize(width: 2.2, height: 2.2))
        p.move(to: CGPoint(x: 6, y: 1)); p.addLine(to: CGPoint(x: 6, y: 19))
        p.move(to: CGPoint(x: 9, y: 11)); p.addLine(to: CGPoint(x: 11.5, y: 5)); p.addLine(to: CGPoint(x: 14, y: 11))
        p.move(to: CGPoint(x: 10, y: 8.7)); p.addLine(to: CGPoint(x: 13, y: 8.7))
        p.move(to: CGPoint(x: 9, y: 14.5)); p.addLine(to: CGPoint(x: 14.5, y: 14.5))
        return p.applying(CGAffineTransform(scaleX: rect.width / 20, y: rect.height / 20))
    }
}
