//
//  ProfileStatItemView.swift
//  BookMate-mini
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
                .foregroundStyle(.black)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("Brown"))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileStatItemView(value: "", label: "")
}
