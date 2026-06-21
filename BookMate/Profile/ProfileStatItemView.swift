//
//  ProfileStatItemView.swift
//  BookMate
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI

struct ProfileStatItemView: View {
    let value: String
    let label: String
    
    var body: some View {
        
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary").opacity(0.9))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("TextPrimary").opacity(0.56))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileStatItemView(value: "", label: "")
}
