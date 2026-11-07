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
