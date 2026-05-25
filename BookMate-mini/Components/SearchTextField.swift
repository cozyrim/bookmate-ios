import SwiftUI

//- 검색창 모양
//- 입력값 바인딩
//- placeholder 받기
//- 엔터 눌렀을 때 실행할 동작 받기
//- 필요하면 X 버튼으로 입력값 비우기
struct SearchTextField: View {
    @Binding var searchText: String
    
    let placeholder: String
    var isDisabled: Bool = false
    var onSubmit: () -> Void = {}
    
    var body: some View {
        
        HStack{
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("Brown").opacity(0.7))
            
            TextField(
                "",
                text: $searchText,
                prompt: Text(placeholder)
                    .foregroundStyle(.black.opacity(0.6))
            )
            .submitLabel(.search)
            .disabled(isDisabled)
            .onSubmit {
                onSubmit()
            }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

#Preview {
    SearchTextField(searchText: .constant(""), placeholder: "기본값",isDisabled: false, onSubmit: {})
}
