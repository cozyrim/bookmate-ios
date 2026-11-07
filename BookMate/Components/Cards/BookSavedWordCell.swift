
import SwiftUI

struct BookSavedWordCell: View {

    let text: String
    let partOfSpeech: String
    let meaning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(text)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary").opacity(0.88))

                PartOfSpeechBadge(text: partOfSpeech)
            }

            Text(meaning)
                .font(.callout)
                .foregroundStyle(Color("TextPrimary").opacity(0.72))
                .lineSpacing(4)
                .lineLimit(3)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ReadingSurface())
        .padding(.horizontal, 28)
    }
}

#Preview {
    BookSavedWordCell(
        text: Word.sampleWords[0].text,
        partOfSpeech: Word.sampleWords[0].partOfSpeech,
        meaning: Word.sampleWords[0].meaning
    )
}
