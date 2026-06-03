//
//  BookSavedWordCell.swift
//  BookMate
//
//  Created by 한채림 on 5/14/26.
//

import SwiftUI

//struct BookSavedWordCell: View {
//    let text: String
//    let partOfSpeech: String
//    let meaning: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack(alignment: .center, spacing: 10) {
//                Text("\(text)")
//                    .font(.title)
//                    .fontWeight(.bold)
//                
//                Text("\(partOfSpeech)")
//                    .font(.caption2)
//                    .foregroundStyle(Color("TextSecondary"))
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 6)
//                    .background(Color("SurfaceSoft"))
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
//            }
//            
//            Text("\(meaning)")
//                .font(.body)
//        }
//        .padding(20)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(
//            RoundedRectangle(cornerRadius: 28)
//                .fill(Color("Surface"))
//        )
//        .padding(.horizontal, 28)
//        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
//    }
//}
//
//#Preview {
//    BookSavedWordCell(
//        text: Word.sampleWords[0].text,
//        partOfSpeech: Word.sampleWords[0].partOfSpeech,
//        meaning: "저속한 작품. 또는 공예품. 본래는 예술 가치가 없는 것을 뜻하나, 현대에 와서는 대중문화의 한 속성으로..."
//    )
//}


    struct BookSavedWordCell: View {
        let text: String
        let partOfSpeech: String
        let meaning: String

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(text)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary").opacity(0.88))

                    Text(partOfSpeech)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary").opacity(0.45))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("Surface").opacity(0.45))
//                        .background(Color.blue.opacity(0.11))
                        .clipShape(Capsule())
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
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color("Surface").opacity(0.82),
                                        Color("Surface").opacity(0.48),
                                        Color(red: 0.92, green: 0.98, blue: 1.0).opacity(0.34)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("Surface").opacity(0.95),
                                Color("Surface").opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .white.opacity(0.45), radius: 8, x: -3, y: -3)
            .shadow(color: Color("Shadow").opacity(0.04), radius: 16, x: 0, y: 8)
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

#Preview {
    BookSavedWordCell(
        text: Word.sampleWords[0].text,
        partOfSpeech: Word.sampleWords[0].partOfSpeech,
        meaning: Word.sampleWords[0].meaning
    )
}
