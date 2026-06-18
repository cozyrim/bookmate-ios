//
//  SingleDatePickerSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/13/26.
//

import SwiftUI

struct SingleDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

        let title: String
        @Binding var selectedDate: Date

    var body: some View {
        NavigationStack {
                    VStack(spacing: 20) {
                        DatePicker(title, selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)

                        Button {
                            dismiss()
                        } label: {
                            Text("선택 완료")
                                .font(.headline)
                                .foregroundStyle(Color("PrimaryButtonText"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("Primary"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(24)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("취소") { dismiss() }
                        }
                    }
        }
    }
}
