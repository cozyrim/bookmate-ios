//
//  SettingsComponents.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI

struct SettingsScreenHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label : {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color("Brown"))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.black)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("Brown"))
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    content
                }
                .background(Color.white.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.045), radius: 14, x: 0, y: 6)
            }
        }
}

struct SettingsToggleRow: View {
    let iconName: String
        let title: String
        let subtitle: String?
        @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            settingsIcon(iconName)
            
            VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)

                            if let subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Color("Brown").opacity(0.75))
                            }
                        }
                        Spacer()

                        Toggle("", isOn: $isOn)
                            .labelsHidden()
                            .tint(Color("Peach"))
                    }
                    .padding(.horizontal, 20)
                    .frame(minHeight: 72)
                    .contentShape(Rectangle())
        }
}

struct SettingsValueRow: View {
    let iconName: String
    let title: String
    let value: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 16) {
            settingsIcon(iconName)

            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.black)

            Spacer()

            Text(value)
                .font(.callout)
                .foregroundStyle(Color("Brown").opacity(0.78))
                .lineLimit(1)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color("Brown").opacity(0.55))
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 72)
        .contentShape(Rectangle())
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color("Brown").opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 72)
    }
}

struct SettingsPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(Color("Peach"))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: Color("Peach").opacity(0.25), radius: 14, x: 0, y: 8)
        }
    }
}

private func settingsIcon(_ iconName: String) -> some View {
    Image(systemName: iconName)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(Color("PeachRedHeavy"))
        .frame(width: 44, height: 44)
        .background(Color("Peach").opacity(0.16))
        .clipShape(Circle())
}
