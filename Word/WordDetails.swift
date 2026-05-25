//
//  WordDetails.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct WordDetails: View {

    let word: Word
    
    var body: some View {
        ZStack{
            Color.skyblue
                .ignoresSafeArea()
            VStack(spacing: 16){
                HStack{
                    Text("\(word.text)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peachRedHeavy)
                    Spacer()
                    
                    Text("\(word.partOfSpeech)")
                        .font(.caption2)
                        .foregroundStyle(Color.greenHeavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                
                VStack(spacing: 26){
                    Text("\(word.meaning)")
                    
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.skyblue2)
                        )
                        .padding(.horizontal, 28)
                        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 12){
                        HStack{
                            Image(systemName: "long.text.page.and.pencil")
                            Text("내 메모")
                                .font(.title2)
                        }
                        Text("\(word.exampleSentence)")
                    }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.skyblue2)
                        )
                        .padding(.horizontal, 28)
                        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
                }
                
                
            }
        }
    }
}

#Preview {
//    WordDetails(text: Word.sampleWords[0].text, partOfSpeech: Word.sampleWords[0].partOfSpeech, exampleSentence: Word.sampleWords[0].exampleSentence, word: <#Word#>)
    WordDetails(word: Word.sampleWords[0])
}
