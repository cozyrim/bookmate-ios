import SwiftUI

struct ProfileMenuCardView: View {
    let rows: [ProfileMenuItem]
    var onTap: (ProfileMenuItem) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                Button { onTap(row) } label: {
                    ProfileMenuRowView(item: row)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if row.id != rows.last?.id {
                    Divider().padding(.leading, 36)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
