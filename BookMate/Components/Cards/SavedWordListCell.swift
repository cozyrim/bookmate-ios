
import SwiftUI

struct SavedWordListCell: View {
    let text: String
    let partOfSpeech: String
    let meaning: String
    let title: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(text)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary").opacity(0.86))

                PartOfSpeechBadge(text: partOfSpeech)

                Spacer()

                MoreOptionsMenu(
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onMove: onMove
                )
            }

            Text(meaning)
                .font(.callout)
                .foregroundStyle(Color("TextPrimary").opacity(0.72))
                .lineSpacing(4)
                .lineLimit(2)

            HStack(spacing: 6) {
                Image(systemName: "book")
                    .font(.caption2)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            .foregroundStyle(Color("TextSecondary"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            
            
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ReadingSurface())
        .padding(.horizontal, 24)
    }
}

#Preview {
    SavedWordListCell(
        text: Word.sampleWords[0].text,
        partOfSpeech: Word.sampleWords[0].partOfSpeech,
        meaning: Word.sampleWords[0].meaning,
        title: Book.dummyBooks[0].title,
        onEdit: {},
        onDelete: {}
    ) {}
}
