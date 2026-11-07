import XCTest
import RealityKit
@testable import BookMate

@MainActor
final class RoomCharacterTests: XCTestCase {
    func testCameraProjectionAndRayAgreeForPhoneAndTablet() async {
        let rig = MiniRoomCameraRig()
        rig.setFocus(false)
        for size in [CGSize(width: 402, height: 874), CGSize(width: 1032, height: 1376)] {
            rig.setViewport(size)
            let world = SIMD3<Float>(-0.22, 1.53, 1.22)
            guard let point = rig.project(world, viewport: size), let ray = rig.ray(through: point, viewport: size) else {
                return XCTFail("Projection must be visible")
            }
            let expected = simd_normalize(world - ray.origin)
            XCTAssertLessThan(simd_length(expected - ray.direction), 0.001)
        }
    }

    func testZoomClampsAndKeepsHitProjectionAligned() async throws {
        let rig = MiniRoomCameraRig()
        let viewport = CGSize(width: 402, height: 874)
        rig.setViewport(viewport)
        for focused in [true, false] {
            rig.setFocus(focused)
            for request: Float in [-100, 0.85, 1, 1.45, 100, .nan, .infinity] {
                rig.setZoom(request)
                XCTAssertGreaterThanOrEqual(rig.zoom, 0.85)
                XCTAssertLessThanOrEqual(rig.zoom, 1.45)
                let world = SIMD3<Float>(-1.69, 1.4, -1.2)
                let point = try XCTUnwrap(rig.project(world, viewport: viewport))
                let ray = try XCTUnwrap(rig.ray(through: point, viewport: viewport))
                XCTAssertLessThan(simd_length(simd_normalize(world - ray.origin) - ray.direction), 0.001)
            }
        }
        rig.setZoom(100)
        XCTAssertEqual(rig.zoom, 1.45)
        rig.setZoom(-100)
        XCTAssertEqual(rig.zoom, 0.85)
        rig.setZoom(.nan)
        XCTAssertEqual(rig.zoom, 1)
    }

    func testCameraGesturesCanTransitionFromPanToPinch() async {
        let coordinator = MiniRoomRealityCanvas.Coordinator()
        let pan = UIPanGestureRecognizer()
        let pinch = UIPinchGestureRecognizer()
        let tap = UITapGestureRecognizer()
        XCTAssertTrue(coordinator.gestureRecognizer(pan, shouldRecognizeSimultaneouslyWith: pinch))
        XCTAssertFalse(coordinator.gestureRecognizer(tap, shouldRecognizeSimultaneouslyWith: pinch))
        XCTAssertTrue(coordinator.gestureRecognizerShouldBegin(pinch))
        coordinator.active = false
        XCTAssertFalse(coordinator.gestureRecognizerShouldBegin(pinch))
        coordinator.active = true
        coordinator.openingID = UUID()
        XCTAssertFalse(coordinator.gestureRecognizerShouldBegin(pinch))
    }

    func testViewpointTransitionIsContinuousAndLatestSelectionWins() async throws {
        let rig = MiniRoomCameraRig()
        let size = CGSize(width: 402, height: 874)
        rig.setViewport(size)
        let start = rig.entity.position
        rig.setViewpoint(.reading, animated: true)
        XCTAssertTrue(rig.isTransitioning)
        XCTAssertEqual(rig.entity.position, start, "Selecting a view must not jump")
        for _ in 0..<3 { rig.advance(deltaTime: 0.05) }
        XCTAssertGreaterThan(simd_distance(start, rig.entity.position), 0.01)
        let interrupted = rig.entity.position
        rig.setViewpoint(.window, animated: true)
        XCTAssertEqual(rig.entity.position, interrupted)
        for _ in 0..<20 {
            rig.advance(deltaTime: 0.05)
            let world = SIMD3<Float>(0.95, 1.95, -1.65)
            let point = try XCTUnwrap(rig.project(world, viewport: size))
            let ray = try XCTUnwrap(rig.ray(through: point, viewport: size))
            XCTAssertLessThan(simd_length(simd_normalize(world - ray.origin) - ray.direction), 0.001)
        }
        XCTAssertFalse(rig.isTransitioning)
        let direct = MiniRoomCameraRig()
        direct.setViewport(size)
        direct.setViewpoint(.window, animated: false)
        XCTAssertLessThan(simd_distance(rig.entity.position, direct.entity.position), 0.001)
    }

    func testReduceMotionFinishesCameraTransitionAndPresetsResetZoom() async {
        let rig = MiniRoomCameraRig()
        rig.setViewport(CGSize(width: 402, height: 874))
        rig.setZoom(1.45)
        rig.setViewpoint(.reading, animated: true)
        XCTAssertEqual(rig.zoom, 1)
        XCTAssertTrue(rig.isTransitioning)
        rig.setViewpoint(.reading, animated: false)
        XCTAssertFalse(rig.isTransitioning)
        let direct = MiniRoomCameraRig()
        direct.setViewport(CGSize(width: 402, height: 874))
        direct.setViewpoint(.reading, animated: false)
        XCTAssertLessThan(simd_distance(rig.entity.position, direct.entity.position), 0.001)
    }

    func testCoordinatorResetsZoomAfterCapturingVisiblePose() async throws {
        let coordinator = MiniRoomRealityCanvas.Coordinator()
        let size = CGSize(width: 402, height: 874)
        coordinator.room.setViewport(size)
        coordinator.configureCamera(viewpoint: .shelf, zoom: 1.45, animated: false)
        let before = try XCTUnwrap(coordinator.room.characterScreenPoint(in: size))
        coordinator.configureCamera(viewpoint: .reading, zoom: 1, animated: true)
        let after = try XCTUnwrap(coordinator.room.characterScreenPoint(in: size))
        XCTAssertEqual(after.x, before.x, accuracy: 0.001)
        XCTAssertEqual(after.y, before.y, accuracy: 0.001)
        XCTAssertTrue(coordinator.room.isCameraTransitioning)
        XCTAssertEqual(coordinator.zoom, 1)
    }

    func testClearingOpeningIntentCancelsPendingNavigation() async {
        let coordinator = MiniRoomRealityCanvas.Coordinator()
        var navigated = false
        coordinator.onHit = { _ in navigated = true }
        let book = Book(title: "취소 확인", author: "", imageName: "", progress: 0)
        coordinator.room.updateBooks([book])
        coordinator.open(book.id)
        let cancelledTask = coordinator.openingTask
        XCTAssertNotNil(coordinator.openingID)
        coordinator.synchronizeOpening(nil, active: true)
        XCTAssertNil(coordinator.openingID)
        XCTAssertNil(coordinator.openingTask)
        await cancelledTask?.value
        XCTAssertFalse(navigated)
        coordinator.reduceMotion = true
        coordinator.synchronizeOpening(book.id, active: true)
        await coordinator.openingTask?.value
        XCTAssertTrue(navigated, "A fresh request must still open the same book")
    }

    func testPausingInteractiveCameraPreservesTargetAndReduceMotionSettlesPendingInput() async {
        let rig = MiniRoomCameraRig()
        let viewport = CGSize(width: 390, height: 440)
        rig.setViewport(viewport)
        rig.orbit(to: 0.8, smooth: true)
        rig.advance(deltaTime: 1.0 / 60)
        let selectedPose = rig.entity.transform
        rig.finishTransition(settleInteractive: false)
        for _ in 0..<90 { rig.advance(deltaTime: 1.0 / 60, interactiveEnabled: false) }
        XCTAssertEqual(rig.entity.position, selectedPose.translation)
        XCTAssertEqual(rig.entity.orientation, selectedPose.rotation)

        for _ in 0..<90 { rig.advance(deltaTime: 1.0 / 60) }
        let direct = MiniRoomCameraRig()
        direct.setViewport(viewport)
        direct.orbit(to: 0.8)
        XCTAssertLessThan(simd_distance(rig.entity.position, direct.entity.position), 0.001)
        rig.setZoom(1.45, smooth: true)
        rig.setViewpoint(.shelf, animated: false)
        direct.setZoom(1.45)
        XCTAssertLessThan(simd_distance(rig.entity.position, direct.entity.position), 0.001)
        let settled = rig.entity.position
        rig.advance(deltaTime: 0.1)
        XCTAssertEqual(rig.entity.position, settled)
    }

    func testInteractiveCameraMotionConvergesWithoutJumpingAndKeepsProjectionAligned() async throws {
        let rig = MiniRoomCameraRig()
        let size = CGSize(width: 390, height: 440)
        rig.setViewport(size)
        let before = rig.entity.position
        rig.orbit(to: 0.8, smooth: true)
        rig.setZoom(1.3, smooth: true)
        XCTAssertEqual(before, rig.entity.position)
        for _ in 0..<90 {
            rig.advance(deltaTime: 1.0 / 60)
            let world = SIMD3<Float>(-1.5, 1.15, -1.5)
            let point = try XCTUnwrap(rig.project(world, viewport: size))
            let ray = try XCTUnwrap(rig.ray(through: point, viewport: size))
            XCTAssertLessThan(simd_distance(ray.direction, simd_normalize(world - ray.origin)), 0.001)
        }
        let direct = MiniRoomCameraRig()
        direct.setViewport(size)
        direct.orbit(to: 0.8)
        direct.setZoom(1.3)
        XCTAssertLessThan(simd_distance(rig.entity.position, direct.entity.position), 0.001)
    }

    func testLatestDestinationWinsDuringMovement() async {
        let character = RoomCharacterController()
        character.setIntent(.window, reduceMotion: false)
        character.update(deltaTime: 0.05)
        character.setIntent(.shelf, reduceMotion: false)
        character.setIntent(.window, reduceMotion: false)
        for _ in 0..<400 { character.update(deltaTime: 0.05) }
        XCTAssertFalse(character.isWalking)
        XCTAssertEqual(character.root.position.x, 0.50, accuracy: 0.01)
        XCTAssertEqual(character.root.position.z, -0.80, accuracy: 0.01)
    }

    func testWalkToSofaAvoidsTableAndFinishesSeated() async {
        let character = RoomCharacterController()
        character.setIntent(.reading, reduceMotion: false)
        for _ in 0..<600 {
            character.update(deltaTime: 0.05)
            let p = character.root.position
            let intersectsTable = p.x > -0.76 && p.x < 1.20 && p.z > 0.67 && p.z < 1.83
            XCTAssertFalse(intersectsTable, "Character crosses the table footprint")
        }
        XCTAssertFalse(character.isWalking)
        XCTAssertEqual(character.root.position.y, 1.00, accuracy: 0.01)
        XCTAssertEqual(character.root.position.x, 1.68, accuracy: 0.01)
    }

    func testReduceMotionCompletesLatestCommandImmediately() async {
        let character = RoomCharacterController()
        character.setIntent(.reading, reduceMotion: false)
        character.setIntent(.window, reduceMotion: false)
        character.setIntent(.seated, reduceMotion: true)
        XCTAssertFalse(character.isWalking)
        XCTAssertEqual(character.root.position.y, 1.00, accuracy: 0.01)
        for _ in 0..<400 { character.update(deltaTime: 0.05) }
        XCTAssertEqual(character.root.position.y, 1.00, accuracy: 0.01)
    }
}
