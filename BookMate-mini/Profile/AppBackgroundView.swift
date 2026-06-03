//
//  AppBackgroundView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct AppBackgroundView: View {
    @AppStorage("selectedBackgroundTheme") private var selectedThemeRawValue = AppBackgroundTheme.skyblue.rawValue
    @AppStorage("customBackgroundImageFileName") private var customBackgroundImageFileName = ""
    
    private var selectedTheme: AppBackgroundTheme {
        AppBackgroundTheme(rawValue: selectedThemeRawValue) ?? .skyblue
    }
    
    @ViewBuilder
    private var backgroundContent: some View {
        switch selectedTheme {
        case .skyblue:
            Color.skyblue
        case .nature:
            ZStack {
                Image("자연4")
                    .resizable()
                    .scaledToFill()
                
                Color.white.opacity(0.15)
            }
        case .peach:
            LinearGradient(
                colors: [
                    Color("Peach").opacity(0.28),
                    Color.skyblue,
                    Color.white.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            LinearGradient(
                colors: [
                    Color(red: 0.83, green: 0.94, blue: 0.86),
                    Color.skyblue,
                    Color.white.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .customPhoto:
            if let image = BackgroundImageStore.loadImage(fileName: customBackgroundImageFileName) {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 2)
                        .saturation(0.75)
                        .brightness(0.04)
                    
                    LinearGradient(
                        colors: [
                            Color.skyblue.opacity(0.78),
                            Color.white.opacity(0.62),
                            Color.skyblue.opacity(0.78)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    Color.white.opacity(0.10)
                }
            } else {
                Color.skyblue
            }
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
                backgroundContent
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        
    }
}
#Preview {
    AppBackgroundView()
}
