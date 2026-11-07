import SwiftUI

struct MiniRoomThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthSessionViewModel

    private let currentTheme: MiniRoomTheme
    private let onApplyWoodRoom: (Bool) -> Void
    @State private var selection: RoomThemeChoice
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(currentTheme: MiniRoomTheme, usesWoodRoom: Bool, onApplyWoodRoom: @escaping (Bool) -> Void) {
        self.currentTheme = currentTheme
        self.onApplyWoodRoom = onApplyWoodRoom
        _selection = State(initialValue: usesWoodRoom ? .wood3D : .illustration(currentTheme))
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                SettingsScreenHeader(title: "서재 배경")

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("내 방에 어울리는 분위기를 골라보세요.")
                            .font(.callout)
                            .foregroundStyle(Color("TextSecondary"))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 14) {
                            MiniRoomThemeOptionCard(theme: .wood3D, isSelected: selection == .wood3D) {
                                selection = .wood3D
                            }
                            .accessibilityIdentifier("miniRoom.theme.wood3D")

                            ForEach(MiniRoomTheme.allCases) { theme in
                                MiniRoomThemeOptionCard(
                                    theme: .illustration(theme),
                                    isSelected: selection == .illustration(theme)
                                ) {
                                    selection = .illustration(theme)
                                }
                            }
                        }
                        .disabled(isSaving)

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

        guard case .illustration(let selectedTheme) = selection else {
            onApplyWoodRoom(true)
            dismiss()
            return
        }

        if selectedTheme == currentTheme {
            onApplyWoodRoom(false)
            dismiss()
            return
        }

        Task {
            isSaving = true
            errorMessage = nil

            let success = await authViewModel.updateMiniRoomTheme(selectedTheme)

            isSaving = false

            if success {
                onApplyWoodRoom(false)
                dismiss()
            } else {
                errorMessage = authViewModel.errorMessage ?? "배경을 저장하지 못했어요."
            }
        }
    }
}

private enum RoomThemeChoice: Equatable {
    case wood3D
    case illustration(MiniRoomTheme)

    var title: String {
        switch self {
        case .wood3D: "원목 서재 3D"
        case .illustration(let theme): theme.title
        }
    }

    var subtitle: String {
        switch self {
        case .wood3D: "이 기기에서 보는 입체 서재"
        case .illustration(let theme): theme.subtitle
        }
    }
}

private struct MiniRoomThemeOptionCard: View {
    let theme: RoomThemeChoice
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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var themePreview: some View {
        switch theme {
        case .wood3D:
            ZStack {
                Color(red: 0.27, green: 0.17, blue: 0.12)
                Image(systemName: "cube.transparent")
                    .font(.system(size: 45, weight: .light))
                    .foregroundStyle(Color(red: 0.96, green: 0.77, blue: 0.55))
            }
            .accessibilityHidden(true)
        case .illustration(.dark):
            Image("MiniRoomLayeredRoomBackgroundDark")
                .resizable()
                .scaledToFill()
        case .illustration(.basic):
            Image("MiniRoomLayeredRoomBackground")
                .resizable()
                .scaledToFill()
        case .illustration(let theme):
            ZStack {
                Image("MiniRoomLayeredRoomBackground")
                    .resizable()
                    .scaledToFill()

                theme.sceneTintColor
                    .opacity(theme.sceneTintOpacity)
                    .blendMode(.softLight)

                theme.sceneTintColor
                    .opacity(theme.sceneTintOpacity * 0.42)
                    .blendMode(.color)
            }
            .compositingGroup()
        }
    }
}

#Preview {
    MiniRoomThemePickerView(currentTheme: .dark, usesWoodRoom: false, onApplyWoodRoom: { _ in })
        .environmentObject(AuthSessionViewModel())
}
