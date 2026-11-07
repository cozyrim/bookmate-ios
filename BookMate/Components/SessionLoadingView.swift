import SwiftUI

/// Matches the system launch artwork; session readiness, never a timer, controls dismissal.
struct SessionLoadingView: View {
    @State private var showsConnectionState = false

    var body: some View {
        ZStack {
            Color("AppBackground")
            Image("LaunchBrand").resizable().scaledToFit()
                .frame(width: 112, height: 112)
                .accessibilityLabel("앱을 여는 중")
                .accessibilityIdentifier("launch.brand")
                .overlay(alignment: .bottom) {
                    if showsConnectionState {
                        Text("로그인 상태를 확인하고 있어요.")
                            .font(.callout)
                            .foregroundStyle(Color("TextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 260)
                            .alignmentGuide(.bottom) { dimensions in
                                dimensions[.top] - 16
                            }
                            .accessibilityIdentifier("launch.connectionState")
                    }
                }
        }
        .ignoresSafeArea()
        .task {
            do { try await Task.sleep(for: .seconds(1)) }
            catch { return }
            showsConnectionState = true
        }
    }
}
