import SwiftUI

/// An open room in perspective: two walls, a floor, and a small shelf.
struct ReadingRoomTabIcon: View {
    var body: some View {
        ReadingRoomShape()
            .stroke(style: StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round))
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}

private struct ReadingRoomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 2, y: 6))
        for point in [CGPoint(x: 10, y: 2), CGPoint(x: 18, y: 6), CGPoint(x: 18, y: 14),
                      CGPoint(x: 10, y: 18), CGPoint(x: 2, y: 14)] {
            path.addLine(to: point)
        }
        path.closeSubpath()
        path.move(to: CGPoint(x: 10, y: 2))
        path.addLine(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 2, y: 14))
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 18, y: 14))
        path.move(to: CGPoint(x: 4, y: 11))
        path.addLine(to: CGPoint(x: 8, y: 9))
        path.move(to: CGPoint(x: 4.5, y: 10.75))
        path.addLine(to: CGPoint(x: 4.5, y: 8.5))
        path.move(to: CGPoint(x: 6.5, y: 9.75))
        path.addLine(to: CGPoint(x: 6.5, y: 7.5))
        return path.applying(CGAffineTransform(scaleX: rect.width / 20, y: rect.height / 20))
    }
}
