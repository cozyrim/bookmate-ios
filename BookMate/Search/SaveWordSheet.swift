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
    @AppStorage("lastSelectedBookId") private var lastSelectedBookId = ""
    @AppStorage("remembersLastSelectedBook") private var remembersLastSelectedBook = true
    
    let text: String
    let meaning: String
    var imageName: String
    let onSaveComplete: () -> Void
    let onRegisterBookTap: () -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
            .background(Color("PrimarySoft"))
            
            VStack(alignment: .leading, spacing: 12){
                HStack{
                Text("어느 책에 저장할까요?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextPrimary").opacity(0.72))
                
                    Spacer()

                        Button {
                            viewModel.prepareWordSaveAfterBookRegistration()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onRegisterBookTap()
                            }
                        } label: {
                            Label("책 등록", systemImage: "plus")
                                .font(.caption.bold())
                                .foregroundStyle(Color("PrimaryButtonText"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color("Primary"), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                if viewModel.booksOnShelf.isEmpty {
                    Text("먼저 책을 등록해 주세요.")
                        .font(.caption)
                        .foregroundStyle(Color("Error"))
                        .padding(.vertical, 12)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(viewModel.booksOnShelf) { book in
                                Button {
                                    selectedBookId = selectedBookId == book.id ? nil : book.id
                                    
                                    if selectedBookId == book.id {
                                        lastSelectedBookId = book.id.uuidString
                                    }
                                } label: {
                                    selectableBookCover(book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12){
                Text("책 속 문장")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextPrimary").opacity(0.72))
                
                TextField(
                    "",
                    text: $bookComment,
                    prompt: Text("단어가 포함된 문장을 적어두면 기억하기 좋아요.")
                        .font(.callout)
                        .foregroundStyle(Color("PrimaryDeep").opacity(0.45)),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                .background(Color("PrimarySoft").opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28)
                    .stroke(Color("Border").opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.04), radius: 8)
            }
            
            Spacer()
            
            if let errorMessage = viewModel.operationErrorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color("Error"))
            }
            
            HStack{
                
                Button {
                    viewModel.cancelWordSaveAfterBookRegistration()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        
                        Text("나중에")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryDeep"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("Surface"))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28)
                        .stroke(Color("Border").opacity(0.08), lineWidth: 2 )
                    )
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
                
                SaveButton {
                    guard !viewModel.booksOnShelf.isEmpty else {
                        viewModel.operationErrorMessage = "책을 먼저 등록해 주세요."
                        viewModel.showToast("책을 먼저 등록해 주세요.", style: .error)
                        return
                    }

                    guard let selectedBookId else {
                        viewModel.showToast("저장할 책을 선택해 주세요.", style: .error)
                        return
                    }

                    Task {
                        let success = await viewModel.saveDictionaryResult(to: selectedBookId, exampleSentence: bookComment)
                        
                        if success {
                            viewModel.cancelWordSaveAfterBookRegistration()
                            viewModel.searchText = ""
                            viewModel.dictionarySearchResult = nil
                            viewModel.dictionarySuggestions = []
                            
                            dismiss()
                            onSaveComplete()
                        }
                    }
                }
                
            }
        }
        .padding(24)
        .onAppear {
            selectInitialBookIfNeeded()
        }
        
    }

    private func selectInitialBookIfNeeded() {
        guard selectedBookId == nil else { return }

        if let registeredBookId = viewModel.wordSaveBookIdToSelectAfterRegistration,
           viewModel.booksOnShelf.contains(where: { $0.id == registeredBookId }) {
            selectedBookId = registeredBookId
            lastSelectedBookId = registeredBookId.uuidString
            return
        }

        guard remembersLastSelectedBook,
              let lastBookUUID = UUID(uuidString: lastSelectedBookId),
              viewModel.booksOnShelf.contains(where: { $0.id == lastBookUUID }) else {
            return
        }

        selectedBookId = lastBookUUID
    }

    private func selectableBookCover(_ book: Book) -> some View {
        let isSelected = selectedBookId == book.id

        return VStack(spacing: 8) {
            BookCoverCell(
                isSelected: isSelected,
                imageName: book.imageName,
                width: 54
            )
            .padding(.trailing, -12)
            .frame(width: 64, height: 86)

            Text(book.title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? Color("Primary") : Color("TextPrimary").opacity(0.88))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 78, height: 18, alignment: .center)
        }
        .frame(width: 82)
    }

}

#Preview {
    SaveWordSheet(
        viewModel: BookMateViewModel(), text: Word.sampleWords[0].text,
        meaning: Word.sampleWords[0].meaning,
        imageName: Book.dummyBooks[2].imageName,
        onSaveComplete: {},
        onRegisterBookTap: {}
    )
}
