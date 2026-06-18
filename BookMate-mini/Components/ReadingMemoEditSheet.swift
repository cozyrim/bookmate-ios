//
//  ReadingMemoEditSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/9/26.
//

import SwiftUI

struct ReadingMemoEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BookMateViewModel

    let memo: ReadingMemo

    @State private var selectedDate = Date()
    @State private var isShowingDatePicker = false
    @State private var page: String
    @State private var text: String

    init(viewModel: BookMateViewModel, memo: ReadingMemo) {
            self.viewModel = viewModel
            self.memo = memo
            _selectedDate = State(initialValue: BookMateDateFormatter.date(from: memo.date) ?? Date())
            _page = State(initialValue: memo.page != nil ? String(memo.page!) : "")
            _text = State(initialValue: memo.text)
        }

    var body: some View {

        NavigationStack {
                    ZStack {
                        Color("AppBackground").ignoresSafeArea()

                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("날짜")
                                            .font(.subheadline)
                                            .foregroundStyle(Color("TextMuted"))
                                        Button {
                                            isShowingDatePicker = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "calendar")
                                                Text(BookMateDateFormatter.display.string(from: selectedDate))
                                                Spacer()
                                            }
                                            .padding(16)
                                            .background(Color("Surface"))
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                        .buttonStyle(.plain)
                                        .sheet(isPresented: $isShowingDatePicker) {
                                            SingleDatePickerSheet(title: "메모 날짜", selectedDate: $selectedDate)
                                                .presentationDetents([.medium])
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("페이지 (선택)")
                                            .font(.subheadline)
                                            .foregroundStyle(Color("TextMuted"))
                                        TextField("예) 42", text: $page)
                                            .keyboardType(.numberPad).padding(16).background(Color("Surface")).clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("메모 내용")
                                        .font(.subheadline)
                                        .foregroundStyle(Color("TextMuted"))
                                    TextEditor(text: $text)
                                        .scrollContentBackground(.hidden).padding(16).frame(minHeight: 140)
                                        .background(Color("Surface"))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                Button {
                                    Task {
                                        let memoDate = BookMateDateFormatter.api.string(from: selectedDate)

                                        let updatedMemo = ReadingMemo(
                                            id: memo.id,
                                            bookId: memo.bookId,
                                            date: memoDate,
                                            page: Int(page),
                                            text: text
                                        )
                                        let success = await viewModel.updateReadingMemo(updatedMemo)
                                        if success { dismiss() }
                                    }
                                } label: {
                                    Text("수정 완료")
                                        .font(.headline)
                                        .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color("TextSecondary") : Color("PrimaryButtonText"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color("TextMuted").opacity(0.4) : Color("Primary"))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .padding(24)
                        }
                    }
                    .navigationTitle("메모 수정").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } } }
                }
            }
        }
