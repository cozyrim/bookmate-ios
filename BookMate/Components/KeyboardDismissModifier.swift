//
//  KeyboardDismissModifier.swift
//  BookMate
//
//  Created by Codex on 6/19/26.
//

import SwiftUI
import UIKit

struct KeyboardDismissTapInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            context.coordinator.installGestureIfNeeded(from: view)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.installGestureIfNeeded(from: uiView)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.removeGesture()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var hostView: UIView?
        private var tapGesture: UITapGestureRecognizer?

        func installGestureIfNeeded(from view: UIView) {
            guard tapGesture == nil, let hostView = view.window else { return }

            let gesture = UITapGestureRecognizer(
                target: self,
                action: #selector(dismissKeyboard)
            )
            gesture.cancelsTouchesInView = false
            gesture.delegate = self
            hostView.addGestureRecognizer(gesture)

            self.hostView = hostView
            self.tapGesture = gesture
        }

        func removeGesture() {
            if let tapGesture {
                hostView?.removeGestureRecognizer(tapGesture)
            }

            hostView = nil
            tapGesture = nil
        }

        @objc private func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let touchedView = touch.view else { return true }
            return !touchedView.hasSuperview(ofType: UITextField.self)
                && !touchedView.hasSuperview(ofType: UITextView.self)
                && !touchedView.hasSuperview(ofType: UISearchBar.self)
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background {
            KeyboardDismissTapInstaller()
                .frame(width: 0, height: 0)
        }
    }
}

private extension UIView {
    func hasSuperview(ofType viewType: UIView.Type) -> Bool {
        var currentView: UIView? = self

        while let view = currentView {
            if view.isKind(of: viewType) {
                return true
            }

            currentView = view.superview
        }

        return false
    }
}
