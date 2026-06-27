//
//  DictionaryResultCard.swift
//  BookMate
//
//  Created by 한채림 on 5/12/26.
//

import SwiftUI

struct DictionaryResultCard: View {
    
    let text: String
    let meaning: String
    let partOfSpeech: String
    let exampleSentence: String
    let imageName: String
    let onSaveComplete: () -> Void
    let onRegisterBookTap: () -> Void
    
    @ObservedObject var viewModel: BookMateViewModel
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 10) {
                Text("\(text)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("[\(partOfSpeech)]")
                    .font(.caption2)
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("SurfaceSoft"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("1.\(meaning)")
                .font(.body)

            Text("\"\(exampleSentence)\"")
                .font(.footnote)
                .foregroundStyle(Color("TextSecondary"))
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .background(Color("SurfaceSoft").opacity(0.4))
            
            Button {
                viewModel.cancelWordSaveAfterBookRegistration()
                viewModel.isWordSaveSheetPresented = true
                BMAnalytics.searchResultTap(type: "dictionary_result", entryPoint: "dictionary_result")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark")
                    Text("저장하기")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryButtonText"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("Primary"))
                .clipShape(Capsule())
            }
            .sheet(isPresented: $viewModel.isWordSaveSheetPresented){
                SaveWordSheet(viewModel: viewModel, text: text, meaning: meaning, imageName: imageName, onSaveComplete: onSaveComplete, onRegisterBookTap: onRegisterBookTap)
                    .presentationDragIndicator(.visible)
            }
            .padding(.top, 8)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color("Surface"))
        )
        .padding(.horizontal, 28)
        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
    }
}

#Preview {
    DictionaryResultCard(text: Word.sampleWords[0].text, meaning: Word.sampleWords[0].meaning, partOfSpeech: Word.sampleWords[0].partOfSpeech, exampleSentence: Word.sampleWords[0].exampleSentence ?? "기본 예시문", imageName: Book.dummyBooks[0].imageName, onSaveComplete: {}, onRegisterBookTap: {}, viewModel: BookMateViewModel())
}
