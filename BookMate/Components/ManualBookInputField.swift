import SwiftUI

struct ManualBookInputField: View {
    @Binding var text: String
    let placeholder: String
    let iconName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName).foregroundStyle(Color("TextSecondary")).frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundStyle(Color("TextPrimary"))
                .tint(Color("Primary"))
                .accessibilityLabel(placeholder)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .modifier(ReadingSurface(radius: 12))
    }
}
