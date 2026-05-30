//
//  MoreOptionMenu.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/27/26.
//

import SwiftUI

struct MoreOptionsMenu: View {
    
    let editTitle: String
    let deleteTitle: String
    let moveTitle: String?
    
    let onEdit: () -> Void
    let onDelete: () -> Void
//    “나중에 실행할 삭제 관련 행동”을 외부에서 받아오는 자리
    let onMove: () -> Void
   
    @State private var isShowingSheet = false
    
//    점 3개 버튼
//    sheet 열기
//    sheet에서 선택한 동작을 부모에게 전달
    
    
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
    
    
    var body: some View {
            Button {
                isShowingSheet = true
            } label: {
//                Image("ellipsis-vertical")
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black.opacity(0.55))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .sheet(isPresented: $isShowingSheet) {
                MoreOptionsSheet(
                    editTitle: editTitle,
                    deleteTitle: deleteTitle,
                    moveTitle: moveTitle,
                    onEdit: {
//                        isShowingSheet = false
                        closeSheetThen(onEdit)
                    },
                    onDelete: {
//                        isShowingSheet = false
                        closeSheetThen(onDelete)
                    }, //아직 실행 아님.
                    //“나중에 실행할 행동”을 새로 만들어 넘김.
                    onMove: {
                        closeSheetThen(onMove)
                    }
                )
                .presentationDetents([.medium]) // sheet 높이
                .presentationDragIndicator(.visible) // 위쪽 손잡이 표시 여부
                .presentationBackground(Color.skyblue) // sheet 배경색
            }
    }
    
    private func closeSheetThen(_ action: @escaping () -> Void) {
        isShowingSheet = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            action()
        }
    }
 
    
}

#Preview {
    MoreOptionsMenu(
        onEdit: {
                print("수정")
            },
            onDelete: {
                print("삭제")
            }
    )
}
