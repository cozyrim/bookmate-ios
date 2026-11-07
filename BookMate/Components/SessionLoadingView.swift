import SwiftUI

/// A short brand transition followed by an explicit connection state, never a timed login bypass.
struct SessionLoadingView: View {
    @State private var showsConnectionState = false

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            if showsConnectionState {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical").font(.title2)
                    Text("서재를 준비하고 있어요").font(.headline)
                    Text("로그인 상태를 확인하고 있어요.")
                        .font(.callout).foregroundStyle(Color("TextSecondary"))
                }
                .accessibilityElement(children: .combine)
            } else {
                Image("LaunchBrand").resizable().scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(.rect(cornerRadius: 20))
                    .accessibilityLabel("앱을 여는 중")
            }
        }
        .task {
            do { try await Task.sleep(for: .seconds(1)) }
            catch { return }
            showsConnectionState = true
        }
    }
}
