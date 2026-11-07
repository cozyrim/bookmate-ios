import SwiftUI

/// Keep the system glass tab bar; collapse it only while a scroll is moving.
struct ScrollingTabBarModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var scrolling = false

    func body(content: Content) -> some View {
        content
            .onScrollPhaseChange { _, phase in
                scrolling = phase == .interacting || phase == .decelerating
            }
            .preference(key: CompactTabBarHiddenKey.self, value: scrolling)
            .toolbar(UIDevice.current.userInterfaceIdiom == .phone || scrolling ? .hidden : .visible, for: .tabBar)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: scrolling)
            .onChange(of: scenePhase) { _, _ in scrolling = false }
            .onDisappear { scrolling = false }
    }
}
