//
//  SaveWordSheet.swift
//  BookMate
//
//  Created by 한채림 on 5/13/26.
//

import SwiftUI

struct SaveWordSheet: View {
    @ObservedObject var viewModel: BookMateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var bookComment: String = ""
    @State private var selectedBookId: UUID?
    
    let text: String
    let meaning: String
    var imageName: String
    let onSaveComplete: () -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("단어 저장")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: 8){
                Text("단어")
                    .font(.caption2)
                
                Text("\(text)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("의미")
                    .font(.caption2)
                
                Text("\(meaning)")
                    .font(.callout)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Peach3"))
            
            VStack(alignment: .leading, spacing: 12){
                Text("어느 책에 저장할까요?")
                    .font(.caption2)
                
                HStack{ // 이미지 크기가 안맞아서 나중에 무조건 똑같게 규격 갖춰야할듯
                    ForEach(viewModel.books) { book in
                        Button{
                            selectedBookId = selectedBookId == book.id ? nil : book.id
                        } label: {
                            BookCoverCell(isSelected: selectedBookId == book.id, imageName: book.imageName)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12){
                Text("책 속 문장")
                    .font(.caption2)
                
                TextField(
                    "",
                    text: $bookComment,
                    prompt: Text("단어가 포함된 문장을 적어두면 기억하기 좋아요.")
                        .font(.callout)
                        .foregroundStyle(Color("PeachRedHeavy").opacity(0.45)),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .background(Color.peach3.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.04), radius: 8)
            }
            
            Spacer()
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            HStack{
                
                Button {
                    print("나중에")
                } label: {
                    HStack(spacing: 8) {
                        
                        Text("나중에")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PeachRedHeavy"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.black.opacity(0.08), lineWidth: 2 )
                    )
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
                
                SaveButton {
                    guard let selectedBookId else {
                        print("책을 선택해 주세요.")
                        return
                    }

                    Task {
                        let success = await viewModel.saveDictionaryResult(to: selectedBookId, exampleSentence: bookComment)
                        
                        if success {
                            dismiss()
                            onSaveComplete()
                        } else{
                            print(viewModel.errorMessage ?? "단어 저장 실패")
                        }
                    }
                }
                
            }
        }
        .padding(24)
        
    }

}

#Preview {
    SaveWordSheet(
        viewModel: BookMateViewModel(), text: Word.sampleWords[0].text,
        meaning: Word.sampleWords[0].meaning,
        imageName: Book.dummyBooks[2].imageName,
        onSaveComplete: {}
    )
}
