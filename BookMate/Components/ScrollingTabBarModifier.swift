import SwiftUI

/// Preserve destination visibility requests and hide the bar while scrolling.
struct ScrollingTabBarModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var scrolling = false
    @State private var destinationRequestsHidden = false

    func body(content: Content) -> some View {
        content
            .onScrollPhaseChange { _, phase in
                scrolling = phase == .interacting || phase == .decelerating
            }
            // Read the destination request before adding this modifier's scroll state.
            .onPreferenceChange(CompactTabBarHiddenKey.self) { destinationRequestsHidden = $0 }
            .transformPreference(CompactTabBarHiddenKey.self) { hidden in
                hidden = hidden || scrolling
            }
            .toolbar(UIDevice.current.userInterfaceIdiom == .phone || scrolling || destinationRequestsHidden ? .hidden : .visible, for: .tabBar)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: scrolling)
            .onChange(of: scenePhase) { _, _ in scrolling = false }
            .onDisappear { scrolling = false }
    }
}
