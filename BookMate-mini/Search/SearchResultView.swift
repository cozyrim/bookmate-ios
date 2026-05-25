import SwiftUI

struct SearchResultView: View {
    @ObservedObject var viewModel: BookMateViewModel
    let onSaveComplete: () -> Void
    
    var body: some View {
        ZStack{
            Color.skyblue
                .ignoresSafeArea()
            
            VStack(alignment: .leading){
                SearchTextField(searchText: $viewModel.searchText, placeholder: "사전에서 단어 검색...", isDisabled: viewModel.isLoading) {
                    Task {
                        await viewModel.searchDictionaryEntry()
                    }
                }
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("검색 중...")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                
                if let word = viewModel.dictionarySearchResult {
                    Text("\"\(word.text)\"에 대한 검색 결과입니다.")
                        .font(.callout)
                        .foregroundStyle(Color("Brown"))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                
                    DictionaryResultCard(text: word.text, meaning: word.meaning, partOfSpeech: word.partOfSpeech, exampleSentence: word.exampleSentence ?? "예문이 없습니다.", imageName: "기본 이미지", onSaveComplete: onSaveComplete, viewModel: viewModel, showingSheet: false)
                }
            }
        }
    }
}

#Preview {
    SearchResultView(viewModel: BookMateViewModel(), onSaveComplete: {})
}
