//
//  SwipeBackGestureModifier.swift
//  BookMate
//
//  Created by Codex on 6/22/26.
//

import SwiftUI
import UIKit

private struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> SwipeBackGestureViewController {
        let viewController = SwipeBackGestureViewController()
        viewController.coordinator = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: SwipeBackGestureViewController, context: Context) {
        uiViewController.coordinator = context.coordinator
        uiViewController.enableSwipeBackGesture()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: UINavigationController?

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

private final class SwipeBackGestureViewController: UIViewController {
    weak var coordinator: SwipeBackGestureEnabler.Coordinator?

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        enableSwipeBackGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableSwipeBackGesture()
    }

    func enableSwipeBackGesture() {
        guard let navigationController = nearestNavigationController else { return }

        coordinator?.navigationController = navigationController
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = coordinator
    }

    private var nearestNavigationController: UINavigationController? {
        if let navigationController {
            return navigationController
        }

        var currentParent = parent

        while let viewController = currentParent {
            if let navigationController = viewController as? UINavigationController {
                return navigationController
            }

            if let navigationController = viewController.navigationController {
                return navigationController
            }

            currentParent = viewController.parent
        }

        return nil
    }
}

extension View {
    func enableSwipeBackGesture() -> some View {
        background(SwipeBackGestureEnabler().frame(width: 0, height: 0))
    }
}
