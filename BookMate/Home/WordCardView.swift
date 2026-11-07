import SwiftUI

struct WordCardView: View {
    let word: Word
    var isFeatured = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(word.text).font(.headline).foregroundStyle(Color("TextPrimary"))
                if !word.partOfSpeech.isEmpty { PartOfSpeechBadge(text: word.partOfSpeech) }
                Spacer(minLength: 0)
            }
            Text(word.meaning).font(.callout)
                .foregroundStyle(Color("TextSecondary"))
                .lineLimit(isFeatured ? 3 : 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: isFeatured ? 88 : 72, alignment: .leading)
        .modifier(ReadingSurface())
    }
}
