//
//  WordRecordEditSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/28/26.
//

// 책 속 문장 입력 UI
// 저장 버튼
// 수정된 Word를 부모에게 넘김
// 단어의 책 속 문장 exampleSentence만 수정하는 sheet

// 기존 word를 받음
// → @State에 exampleSentence 초기값 넣음
// → 저장 버튼 누름
// → exampleSentence만 바꾼 updatedWord 생성
// → onSave(updatedWord)

import SwiftUI

struct WordRecordEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let word: Word
    let onSave: (Word) async -> Bool
    
    @State private var exampleSentence: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(
        word: Word,
        onSave: @escaping (Word) async -> Bool) {
        self.word = word
        self.onSave = onSave
        _exampleSentence = State(initialValue: word.exampleSentence ?? "")
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("기록 수정하기")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextPrimary").opacity(0.78))
                .padding(.top, 32)
            
            wordInfoHeader
            
            
            VStack(alignment: .leading, spacing: 12) {
                Text("책 속 문장")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary").opacity(0.82))
                
                TextEditor(text: $exampleSentence)
                    .font(.body)
                    .lineSpacing(6)
                    .padding(16)
                    .frame(height: 150)
                    .scrollContentBackground(.hidden)
                    .background(Color("Surface").opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("Border").opacity(0.12), lineWidth: 1)
                    }
                    .overlay(alignment: .topLeading) {
                        if exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("책에서 만난 문장을 적어보세요.")
                                .font(.body)
                                .foregroundStyle(Color("TextMuted").opacity(0.75))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 24)
                                .allowsHitTesting(false)
                        }
                    }
            }
            
            Spacer()
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color("Error"))
            }
            
            Button {
                let trimmedSentence = exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let updatedWord = Word(
                    id: word.id,
                    text: word.text,
                    meaning: word.meaning,
                    partOfSpeech: word.partOfSpeech,
                    exampleSentence: trimmedSentence.isEmpty ? nil : trimmedSentence,
                    targetCode: word.targetCode,
                    bookId: word.bookId
                )
                
                Task {
                    isSaving = true
                    errorMessage = nil
                    
                    let success = await onSave(updatedWord)
                    
                    isSaving = false
                    
                    if success {
                        dismiss()
                    } else {
                        errorMessage = "기록 수정에 실패했습니다."
                    }
                }
                } label: {
                    Text(isSaving ? "저장 중..." : "저장하기")
                        .disabled(isSaving)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color("Primary"))
                        .clipShape(Capsule())
                        .shadow(color: Color("Primary").opacity(0.28), radius: 14, x: 0, y: 8)
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color("AppBackground"))
        }
    
    private var wordInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word.text)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color("TextPrimary").opacity(0.88))
            
            Text(word.partOfSpeech)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("Primary").opacity(0.78))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.10))
                .clipShape(Capsule())

            Text(word.meaning)
                        .font(.callout)
                        .foregroundStyle(Color("TextPrimary").opacity(0.72))
                        .lineSpacing(5)
                        .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
}



#Preview {
    WordRecordEditSheet(
        word: Word.sampleWords[0],
        onSave: { updatedWord in
                    print("수정된 문장:", updatedWord.exampleSentence ?? "")
                    return true
                }
    )
}
