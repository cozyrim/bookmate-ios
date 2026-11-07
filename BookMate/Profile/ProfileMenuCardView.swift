import SwiftUI

struct ProfileMenuCardView: View {
    @ScaledMetric(relativeTo: .body) private var iconColumnWidth: CGFloat = 24
    let rows: [ProfileMenuItem]
    var onTap: (ProfileMenuItem) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                Button { onTap(row) } label: {
                    ProfileMenuRowView(item: row)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if row.id != rows.last?.id {
                    Divider().padding(.leading, iconColumnWidth + 12)
                }
            }
        }
    }
}
