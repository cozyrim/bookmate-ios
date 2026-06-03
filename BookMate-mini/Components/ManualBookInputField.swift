//
//  ManualBookInputField.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI

struct ManualBookInputField: View {
    @Binding var text: String
    
    let placeholder: String
    let iconName: String
    var body: some View {
        
        HStack{
            Image(systemName: iconName)
                .foregroundStyle(Color(.gray).opacity(0.8))
                .fontWeight(.bold)
            
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundStyle(Color("TextMuted").opacity(0.6))
            )
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        //        .background(Color("SurfaceSoft").opacity(0.6))
        //        .clipShape(Capsule())
        .background {
            Capsule()
                .fill(Color(.skyblue3))
                .overlay{
                    Capsule()
                        .stroke(Color("Border").opacity(0.15), lineWidth: 1)
                        .blur(radius: 2)
                        .offset(y: 2)
                        .mask(Capsule().fill(Color("TextPrimary")))
                }
        }
    }
}
#Preview {
    ManualBookInputField(text: .constant(""), placeholder: "제목을 입력하세요", iconName: "text.book.closed")
}
