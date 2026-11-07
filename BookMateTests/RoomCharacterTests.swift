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
