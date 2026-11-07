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
        
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(Color("TextPrimary"))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileStatItemView(value: "", label: "")
}
