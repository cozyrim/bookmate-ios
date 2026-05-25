//
//  ProfileImageView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileImageView: View {
    let imageName: String
    let onTap: () -> Void
    var body: some View {
        Button {
            onTap()
        } label: {ZStack(alignment: .bottomTrailing) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay{
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white, lineWidth: 5)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                
                
                    Image(systemName: "pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("Brown"))
                        .frame(width: 48, height: 48)
                        .background(Color("Peach"))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        }
                        .shadow(color: Color("Peach").opacity(0.35), radius: 10, x: 0, y:4)
                        .offset(x: 10, y: 10)
            }
        }
        .buttonStyle(.plain)
    }
}
    
#Preview {
    ProfileImageView(imageName: "profileImage"){
        print("이미지 선택 열기")
    }
}
