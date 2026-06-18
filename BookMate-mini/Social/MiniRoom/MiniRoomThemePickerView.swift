import SwiftUI

struct MiniRoomThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthSessionViewModel

    @State private var selectedTheme: MiniRoomTheme
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(selectedTheme: MiniRoomTheme) {
        _selectedTheme = State(initialValue: selectedTheme)
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                SettingsScreenHeader(title: "미니룸 배경")

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("내 방에 어울리는 분위기를 골라보세요.")
                            .font(.callout)
                            .foregroundStyle(Color("TextSecondary"))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(MiniRoomTheme.allCases) { theme in
                                MiniRoomThemeOptionCard(
                                    theme: theme,
                                    isSelected: selectedTheme == theme
                                ) {
                                    selectedTheme = theme
                                }
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color("Error"))
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 110)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            SettingsPrimaryButton(title: isSaving ? "저장 중..." : "배경 적용하기") {
                saveTheme()
            }
            .disabled(isSaving)
            .opacity(isSaving ? 0.7 : 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .background(Color("AppBackground").opacity(0.96))
        }
    }

    private func saveTheme() {
        guard !isSaving else { return }

        Task {
            isSaving = true
            errorMessage = nil

            let success = await authViewModel.updateMiniRoomTheme(selectedTheme)

            isSaving = false

            if success {
                dismiss()
            } else {
                errorMessage = authViewModel.errorMessage ?? "배경을 저장하지 못했어요."
            }
        }
    }
}

private struct MiniRoomThemeOptionCard: View {
    let theme: MiniRoomTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    themePreview
                        .frame(height: 126)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .clipped()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color("PrimaryDeep"))
                            .background(Color("Surface").clipShape(Circle()))
                            .padding(10)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.title)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))

                    Text(theme.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color("TextSecondary").opacity(0.75))
                        .lineLimit(2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Surface").opacity(isSelected ? 0.96 : 0.84))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? Color("Primary").opacity(0.9) : Color("Surface").opacity(0.45),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(color: Color("Shadow").opacity(0.05), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var themePreview: some View {
        switch theme {
        case .dark:
            Image("MiniRoomLayeredRoomBackgroundDark")
                .resizable()
                .scaledToFill()
        case .basic:
            Image("MiniRoomLayeredRoomBackground")
                .resizable()
                .scaledToFill()
        case .pink, .mint:
            ZStack {
                Image("MiniRoomLayeredRoomBackground")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.74)

                theme.backgroundColor
                    .opacity(0.44)
            }
        }
    }
}

#Preview {
    MiniRoomThemePickerView(selectedTheme: .dark)
        .environmentObject(AuthSessionViewModel())
}
