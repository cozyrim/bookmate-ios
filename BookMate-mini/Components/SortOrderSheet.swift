//
//  SortOrderSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/8/26.
//

import SwiftUI

struct SortOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    
    // 현재 선택된 정렬 기준
    let currentOrder: BookMateViewModel.ArchiveSortOrder
    
    // 선택했을 때 호출할 클로저
        let onSelect: (BookMateViewModel.ArchiveSortOrder) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Text("정렬 기준")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.bottom, 20)
            
            Divider()
            
            // ArchiveSortOrder의 모든 케이스를 자동으로 순회
                        ForEach(BookMateViewModel.ArchiveSortOrder.allCases, id: \.self) { order in
                            Button {
                                onSelect(order)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(order.rawValue)   // "최신순", "오래된 순", "가나다순"
                                        .font(.callout)
                                        .fontWeight(currentOrder == order ? .semibold : .regular)
                                        .foregroundStyle(currentOrder == order ? Color("Primary") : Color("TextPrimary"))
                                    
                                    Spacer()
                                    
                                    if currentOrder == order {
                                        Image(systemName: "checkmark")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color("Primary"))
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 18)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                    .presentationBackground(Color("AppBackground"))
    }
}

#Preview {
    SortOrderSheet(
            currentOrder: .latest,
            onSelect: { _ in }
        )
}
