//
//  MoreOptionsSheet.swift
//  BookMate
//
//  Created by 한채림 on 5/27/26.
//

import SwiftUI

struct MoreOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let editTitle: String
    let deleteTitle: String
    let moveTitle: String?
    let memoTitle: String?
    
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    let onMemo: () -> Void

    private var normalOptionColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color("TextPrimary")
    }

    private var sheetRowBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color("Surface")
    }

    private var sheetCornerRadius: CGFloat {
        24
    }
    
    init(
            editTitle: String = "단어 수정하기",
            deleteTitle: String = "단어 삭제하기",
            moveTitle: String? = "다른 책으로 이동",
            memoTitle: String? = nil,
            onEdit: @escaping () -> Void,
            onDelete: @escaping () -> Void,
            onMove: @escaping () -> Void = {},
            onMemo: @escaping () -> Void = {}
        ) {
            self.editTitle = editTitle
            self.deleteTitle = deleteTitle
            self.moveTitle = moveTitle
            self.memoTitle = memoTitle
            self.onEdit = onEdit
            self.onDelete = onDelete
            self.onMove = onMove
            self.onMemo = onMemo
        }
    
    
    private func optionRow( // optionRow 함수는 실행되자마자 Button이라는 View를 만들어서 반환 하지만 action()은 그 순간 바로 실행되는 게 아님, 사용자가 나중에 버튼을 눌렀을 때 실행
        title: String,
        systemImage: String,
        color: Color,
        action: @escaping () -> Void // 이 행을 눌렀을 때 나중에 실행할 코드를 받겠다
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(color.opacity(colorScheme == .dark ? 0.16 : 0.08), in: Circle())

                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

//    얘는 “수정”, “삭제” 같은 버튼만 보여준다.
//    직접 삭제하지 않는다.


    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                optionRow(
                    title: editTitle,
                    systemImage: "pencil",
                    color: normalOptionColor,
                    action: onEdit
                )
            
                if let moveTitle {
                    Divider()
                        .padding(.leading, 56)

                    optionRow(
                        title: moveTitle,
                        systemImage: "rectangle.portrait.and.arrow.right",
                        color: normalOptionColor,
                        action: onMove
                    )
                }

                if let memoTitle {
                    Divider()
                        .padding(.leading, 56)

                    optionRow(
                        title: memoTitle,
                        systemImage: "note.text.badge.plus",
                        color: normalOptionColor,
                        action: onMemo
                    )
                }
                
//                optionRow(title: "목록에서 숨기기", systemImage: "eye.slash", color: .black, action: {
//                        DebugLogger.log("숨기기")
//                    }
//                )
            }
            .background(sheetRowBackground)
            .clipShape(RoundedRectangle(cornerRadius: sheetCornerRadius, style: .continuous))
            
            Button { // 여기서 onDelete()는 “삭제 버튼이 눌렸다”는 사실을 바깥에 알려주는 역할
                onDelete() // 부모가 넘겨준 행동 실행
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(Color("Error").opacity(colorScheme == .dark ? 0.16 : 0.08), in: Circle())

                    Text(deleteTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .foregroundStyle(Color("Error"))
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(sheetRowBackground)
                .clipShape(RoundedRectangle(cornerRadius: sheetCornerRadius, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, moveTitle == nil ? 18 : 0)
            
            Button{
                // sheet 닫기는 부모에서 처리하거나 dismiss 사용 가능
                dismiss()
            } label: {
                Text("취소")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(normalOptionColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(sheetRowBackground)
                    .clipShape(RoundedRectangle(cornerRadius: sheetCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .foregroundStyle(Color("TextPrimary"))

    }

}
    

#Preview {
    MoreOptionsSheet(
        onEdit: {},
        onDelete: {},
        onMove: {}
        )
}
