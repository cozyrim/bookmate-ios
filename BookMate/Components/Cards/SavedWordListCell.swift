//
//  SavedWordListCell.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct SavedWordListCell: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let partOfSpeech: String
    let meaning: String
    let title: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void

    private var cardBackgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color("SurfaceElevated").opacity(0.92),
                Color("SurfaceElevated").opacity(0.82)
            ]
        }

        return [
            Color("Surface").opacity(0.86),
            Color("Surface").opacity(0.66),
            Color(red: 0.92, green: 0.98, blue: 1.0).opacity(0.18)
        ]
    }

    private var cardBorderColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.white.opacity(0.08),
                Color.white.opacity(0.03)
            ]
        }

        return [
            Color("Surface").opacity(0.9),
            Color("Surface").opacity(0.35)
        ]
    }

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
//                
//                Spacer()
//                
//                MoreOptionsMenu(
//                    onEdit:onEdit,
//                    onDelete: onDelete
//                    )
//                
//            }
//
//            Text("\(meaning)")
//                .font(.body)
//
//            Divider()
//            
//            HStack {
//                Image(systemName: "book")
//                Text("\(title)")
//            }
//            .font(.caption)
//            .fontWeight(.semibold)
//            .foregroundStyle(Color("Success"))
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//            .background(Color("SuccessSoft"))
//            .clipShape(Capsule())
//        }
//        .padding(20)
//        .frame(maxWidth: .infinity)
////        .background(
////            RoundedRectangle(cornerRadius: 28)
////                .fill(Color("Surface"))
////        )
////        .padding(.horizontal, 28)
//        
//        .background {
//            ZStack {
//                RoundedRectangle(cornerRadius: 28)
//                    .fill(.ultraThinMaterial)
//
//                RoundedRectangle(cornerRadius: 28)
//                    .fill(
//                        LinearGradient(
//                            colors: [
//                                Color("Surface").opacity(0.45),
//                                Color(red: 0.86, green: 0.94, blue: 1.0).opacity(0.22),
//                                Color(red: 0.72, green: 0.82, blue: 0.91).opacity(0.18)
//                            ],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//            }
//        }
//        .overlay {
//            RoundedRectangle(cornerRadius: 28)
//                .stroke(Color("Surface").opacity(0.55), lineWidth: 1)
//        }
//        .padding(.horizontal, 28)
//        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
//    }
//}

    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(text)
                        .font(.title2)
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
                .foregroundStyle(Color("Success").opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color("SuccessSoft").opacity(0.55))
                .clipShape(Capsule())
                .padding(.top, 2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: cardBackgroundColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: cardBorderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark ? .clear : .white.opacity(0.45),
                radius: 10,
                x: -4,
                y: -4
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.28) : Color("Shadow").opacity(0.035),
                radius: colorScheme == .dark ? 10 : 18,
                x: 0,
                y: colorScheme == .dark ? 6 : 10
            )
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
