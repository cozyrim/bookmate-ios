//
//  AppBackgroundView.swift
//  BookMate
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
                gradient: Gradient(stops: [
                    .init(color: Color("PrimarySoft").opacity(0.58), location: 0.00),
                    .init(color: Color("AppBackgroundSoft").opacity(0.95), location: 0.42),
                    .init(color: Color("AppBackground").opacity(0.98), location: 1.00)
                ]),
                startPoint: .top,
                endPoint: .bottom
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
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color("PrimarySoft").opacity(0.58), location: 0.00),
                        .init(color: Color("AppBackgroundSoft").opacity(0.95), location: 0.42),
                        .init(color: Color("AppBackground").opacity(0.98), location: 1.00)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
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
