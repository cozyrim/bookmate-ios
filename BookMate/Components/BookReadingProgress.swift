import SwiftUI

/// Cover-adjacent progress shared by the home carousel and both shelf layouts.
struct BookReadingProgress: View {
    let progress: Double
    let status: ReadingStatus

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: clampedProgress).tint(Color("Primary"))
                .accessibilityHidden(true)
            Text("\(Int((clampedProgress * 100).rounded()))% 읽음")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Color("TextSecondary"))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 28, alignment: .top)
        .opacity(status.showsReadingProgress ? 1 : 0)
        .accessibilityRepresentation {
            ProgressView(value: clampedProgress) {
                Text("\(Int((clampedProgress * 100).rounded()))% 읽음")
            }
        }
        .accessibilityHidden(!status.showsReadingProgress)
    }
}
