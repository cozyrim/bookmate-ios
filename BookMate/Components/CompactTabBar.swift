import SwiftUI

struct CompactTabBarHiddenKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

private struct CompactTabBarHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var compactTabBarHeight: CGFloat {
        get { self[CompactTabBarHeightKey.self] }
        set { self[CompactTabBarHeightKey.self] = newValue }
    }
}

struct CompactTabBar: View {
    static let height: CGFloat = 58
    @Binding var selection: Int
    private let labels = ["홈", "책", "단어장", "서재", "프로필"]
    private let symbols = ["house", "book", "character.book.closed", "view.3d", "person.crop.circle"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                Button { selection = index } label: {
                    Group {
                        if index == 2 {
                            VocabularyTabIcon()
                        } else if index == 3 {
                            ReadingRoomTabIcon()
                        } else {
                            Image(systemName: symbols[index]).font(.system(size: 20, weight: selection == index ? .semibold : .regular))
                        }
                    }
                    .foregroundStyle(selection == index ? Color("Primary") : Color("TextSecondary"))
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(selection == index ? Color("Primary").opacity(0.12) : .clear, in: Capsule())
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(labels[index])
                .accessibilityAddTraits(selection == index ? [.isSelected] : [])
            }
        }
        .padding(4)
        .modifier(BookMateGlassSurface(radius: 28))
        .frame(maxWidth: 460)
        .padding(.horizontal, 28)
        .padding(.bottom, 6)
        .accessibilityIdentifier("navigation.compactTabs")
    }
}
