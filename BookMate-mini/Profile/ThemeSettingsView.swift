//
//  ThemeSettingsView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI
import PhotosUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackgroundTheme") private var selectedThemeRawValue = AppBackgroundTheme.skyblue.rawValue
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageSaveErrorMessage: String?
    @AppStorage("customBackgroundImageFileName") private var customBackgroundImageFileName = ""
    
    private var selectedTheme: AppBackgroundTheme {
        AppBackgroundTheme(rawValue: selectedThemeRawValue) ?? .skyblue
    }
    
    var body: some View {
        ZStack{
            AppBackgroundView()
            
            VStack(spacing: 24) {
                SettingsScreenHeader(title: "화면 테마")
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("원하는 분위기로 배경을 바꿔보세요.")
                            .font(.callout)
                            .foregroundStyle(Color("Brown"))
                            .padding(.horizontal, 4)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(AppBackgroundTheme.presetThemes) { theme in
                                ThemeOptionCard(
                                    theme: theme,
                                    isSelected: selectedTheme == theme
                                ) {
                                    selectedThemeRawValue = theme.rawValue
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("내 사진으로 설정")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("Brown"))
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 14) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 21, weight: .semibold))
                                        .foregroundStyle(Color("Peach").opacity(0.16))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("사진 선택하기")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.black)
                                        
                                        Text(
                                                            selectedTheme == .customPhoto
                                                            ? "선택한 사진을 배경으로 사용 중이에요."
                                                            : "앨범에서 고른 사진을 배경으로 사용할 수 있어요."
                                                        )
                                                        .font(.caption)
                                                        .foregroundStyle(Color("Brown").opacity(0.75))
                                    }
                                    Spacer()
                                    
                                    if selectedTheme == .customPhoto {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(Color("PeachRedHeavy"))
                                    } else {
                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundStyle(Color("Brown").opacity(0.65))
                                    }
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 86)
                                .background(Color.white.opacity(0.88))
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: .black.opacity(0.045), radius: 14, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                            
                            if let imageSaveErrorMessage {
                                    Text(imageSaveErrorMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 4)
                                }
                        }
                        .padding(.top, 12)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            guard let newItem else { return }
                            
                            Task {
                                do {
                                    guard let data = try await newItem.loadTransferable(type: Data.self) else {
                                        await MainActor.run {
                                            imageSaveErrorMessage = "사진 데이터를 불러오지 못했습니다."
                                        }
                                        return
                                    }
                                    
                                    let fileName = try BackgroundImageStore.saveImageData(data)
                                    
                                    await MainActor.run {
                                        customBackgroundImageFileName = fileName
                                        selectedThemeRawValue = AppBackgroundTheme.customPhoto.rawValue
                                        imageSaveErrorMessage = nil
                                    }
                                } catch {
                                    await MainActor.run {
                                        imageSaveErrorMessage = "사진을 저장하지 못했습니다."
                                    }
                                    print("배경 사진 저장 실패:", error)
                                }
                            }
                                }
                        Button("사진 배경 제거") {
                            BackgroundImageStore.deleteImage(fileName: customBackgroundImageFileName)
                            customBackgroundImageFileName = ""
                            selectedThemeRawValue = AppBackgroundTheme.skyblue.rawValue
                        }
                        
                        
                        SettingsPrimaryButton(title: "저장하기") {
                            dismiss()
                        }
                        .padding(.top, 18)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct ThemeOptionCard: View {
    let theme: AppBackgroundTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    themePreview
                        .frame(height: 108)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .clipped()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color("PeachRedHeavy"))
                            .background(Color.white.clipShape(Circle()))
                            .padding(10)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.title)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                    
                    Text(theme.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color("Brown").opacity(0.75))
                        .lineLimit(2)
                }
            }
            .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(isSelected ? 0.96 : 0.84))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(
                                isSelected ? Color("Peach").opacity(0.9) : Color.white.opacity(0.45),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var themePreview: some View {
        switch theme {
        case .skyblue:
            Color.skyblue
            
            
            // 테마가 자연 배경일 때 패딩이 풀리는 것 같음,,
        case .nature:
            ZStack {
                Image("자연4")
                    .resizable()
                    .scaledToFill()
                
                Color.white.opacity(0.15)
                    .ignoresSafeArea()
            }
            
            
        case .peach:
            LinearGradient(
                colors: [
                    Color("Peach").opacity(0.5),
                    Color.white.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .green:
            LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.91, blue: 0.76),
                    Color.white.opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .customPhoto:
            LinearGradient(
                colors: [
                    Color("Peach").opacity(0.22),
                    Color.skyblue.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color("PeachRedHeavy"))
                
            }
        }
    }
}



#Preview {
    ThemeSettingsView()

}
