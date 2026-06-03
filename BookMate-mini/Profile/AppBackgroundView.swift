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
            LinearGradient(
                colors: [
                    Color("AppBackgroundSoft"),
                    Color("AppBackground"),
                    Color("AccentSoft").opacity(0.62),
                    Color("PrimarySoft").opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
        case .nature:
            ZStack {
                Image("자연4")
                    .resizable()
                    .scaledToFill()
                
                Color("Surface").opacity(0.15)
            }
        case .peach:
            LinearGradient(
                colors: [
                    Color("Primary").opacity(0.28),
                    Color("AppBackground"),
                    Color("Surface").opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            LinearGradient(
                colors: [
                    Color(red: 0.83, green: 0.94, blue: 0.86),
                    Color("AppBackground"),
                    Color("Surface").opacity(0.8)
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
                            Color("AppBackground").opacity(0.78),
                            Color("Surface").opacity(0.62),
                            Color("AppBackground").opacity(0.78)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    Color("Surface").opacity(0.10)
                }
            } else {
                Color("AppBackground")
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
