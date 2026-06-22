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
                colors: [
                    Color("PrimarySoft").opacity(0.96),
                    Color("Skyblue").opacity(0.98),
                    Color("AppBackground").opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .softPink:
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.90, blue: 0.93),
                    Color(red: 0.98, green: 0.95, blue: 0.97),
                    Color("Surface").opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .peach:
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color("PrimarySoft").opacity(0.48), location: 0.00),
                    .init(color: Color("AppBackgroundSoft").opacity(0.95), location: 0.44),
                    .init(color: Color("AppBackground").opacity(0.98), location: 1.00)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .green:
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.97, blue: 0.91),
                    Color("AppBackground").opacity(0.96),
                    Color("Surface").opacity(0.86)
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
                    colors: [
                        Color("PrimarySoft").opacity(0.96),
                        Color("Skyblue").opacity(0.98),
                        Color("AppBackground").opacity(0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
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
