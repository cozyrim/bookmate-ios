//
//  MoreOptionsSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/27/26.
//

import SwiftUI

struct MoreOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let editTitle: String
    let deleteTitle: String
    let moveTitle: String?
    
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    
    init(
            editTitle: String = "단어 수정하기",
            deleteTitle: String = "단어 삭제하기",
            moveTitle: String? = "다른 책으로 이동",
            onEdit: @escaping () -> Void,
            onDelete: @escaping () -> Void,
            onMove: @escaping () -> Void = {}
        ) {
            self.editTitle = editTitle
            self.deleteTitle = deleteTitle
            self.moveTitle = moveTitle
            self.onEdit = onEdit
            self.onDelete = onDelete
            self.onMove = onMove
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
            HStack {
                Text(title)
                    .font(.title3)
                
                Spacer()
                
                Image(systemName: systemImage)
                    .font(.title3)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 24)
            .frame(height: 72)
        }
    }

//    얘는 “수정”, “삭제” 같은 버튼만 보여준다.
//    직접 삭제하지 않는다.


    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                optionRow(
                    title: editTitle,
                    systemImage: "pencil",
                    color: .black,
                    action: onEdit
                )
            
                if let moveTitle {
                    Divider()
                        .padding(.leading, 24)

                    optionRow(
                        title: moveTitle,
                        systemImage: "rectangle.portrait.and.arrow.right",
                        color: .black,
                        action: onMove
                    )
                }
                
                Divider()
                    .padding(.leading, 24)
                
//                optionRow(title: "목록에서 숨기기", systemImage: "eye.slash", color: .black, action: {
//                        print("숨기기")
//                    }
//                )
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            
            Button { // 여기서 onDelete()는 “삭제 버튼이 눌렸다”는 사실을 바깥에 알려주는 역할
                onDelete() // 부모가 넘겨준 행동 실행
            } label: {
                HStack {
                    Text(deleteTitle)
                        .font(.title3)
                    
                    Spacer()
                    
                    Image(systemName: "trash")
                        .font(.title3)
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 24)
                .frame(height: 72)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .padding(.top, moveTitle == nil ? 28 : 0)
            
            Button{
                // sheet 닫기는 부모에서 처리하거나 dismiss 사용 가능
                dismiss()
            } label: {
                Text("취소")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)

    }

}
    

#Preview {
    MoreOptionsSheet(
        onEdit: {
            print("수정")
        },
        onDelete: {
            print("삭제")
        },
        onMove: {
            print("다른 책으로 이동")
        }
        )
}
