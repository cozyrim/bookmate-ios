import XCTest
import UIKit
@testable import BookMate

@MainActor
final class KeyboardDismissGestureTests: XCTestCase {
    func testKeyboardObserverCoexistsWithoutChangingOtherGestureArbitration() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let view = UIView()
        window.addSubview(view)
        let coordinator = KeyboardDismissTapInstaller.Coordinator()
        coordinator.installGestureIfNeeded(from: view)
        let observer = try XCTUnwrap(window.gestureRecognizers?.first { $0.delegate === coordinator })
        let navigation = UITapGestureRecognizer()
        let camera = UIPanGestureRecognizer()
        XCTAssertFalse(observer.cancelsTouchesInView)
        XCTAssertFalse(observer.delaysTouchesEnded)
        XCTAssertTrue(coordinator.gestureRecognizer(observer, shouldRecognizeSimultaneouslyWith: navigation))
        XCTAssertTrue(coordinator.gestureRecognizer(camera, shouldRecognizeSimultaneouslyWith: observer))
        XCTAssertFalse(coordinator.gestureRecognizer(navigation, shouldRecognizeSimultaneouslyWith: camera))
    }

    func testRepeatedInstallationIsIdempotentAndDismantlingRemovesOnlyObserver() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let view = UIView()
        window.addSubview(view)
        let navigation = UITapGestureRecognizer()
        window.addGestureRecognizer(navigation)
        let coordinator = KeyboardDismissTapInstaller.Coordinator()
        coordinator.installGestureIfNeeded(from: view)
        coordinator.installGestureIfNeeded(from: view)
        XCTAssertEqual(window.gestureRecognizers?.filter { $0.delegate === coordinator }.count, 1)
        coordinator.removeGesture()
        XCTAssertEqual(window.gestureRecognizers?.filter { $0.delegate === coordinator }.count ?? 0, 0)
        XCTAssertTrue(window.gestureRecognizers?.contains(navigation) == true)
        coordinator.installGestureIfNeeded(from: view)
        XCTAssertEqual(window.gestureRecognizers?.filter { $0.delegate === coordinator }.count, 1)
    }
}
