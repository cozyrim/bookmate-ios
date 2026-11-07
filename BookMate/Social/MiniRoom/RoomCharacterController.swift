import RealityKit
import UIKit

/// Fixed walkable routes keep the character clear of the existing table and sofa.
/// The renderer owns poses only; reading time and storage live outside this class.
@MainActor
final class RoomCharacterController {
    enum Intent: Equatable { case shelf, window, seated, reading }
    let root = Entity()
    private let leftArm = Entity(), rightArm = Entity()
    private let leftLeg = Entity(), rightLeg = Entity()
    private let leftShin = Entity(), rightShin = Entity()
    private let heldBook = Entity()
    private var intent: Intent = .shelf
    private var route: [SIMD3<Float>] = []
    private var pendingIntent: Intent?
    private var seatingProgress: Float?
    private var seatingStart = SIMD3<Float>.zero
    private var phase: Float = 0
    private var seated = false
    private var reduceMotion = false
    private let hipHeight: Float = 0.72
    private let shelf: SIMD3<Float> = [-1.05, 0.72, -0.45]
    private let window: SIMD3<Float> = [0.50, 0.72, -0.80]
    private let passage: SIMD3<Float> = [-1.05, 0.72, 0.55]
    private let frontLeft: SIMD3<Float> = [-1.05, 0.72, 1.98]
    private let frontSeat: SIMD3<Float> = [1.20, 0.72, 1.98]
    private let approach: SIMD3<Float> = [1.33, 0.72, 1.50]
    private let seat: SIMD3<Float> = [1.68, 1.00, 0.825]

    init() {
        root.name = "reader"
        root.position = shelf
        root.addChild(part(.generateBox(size: [0.40, 0.44, 0.26], cornerRadius: 0.10), 0x5D80AA, at: [0, 0.25, 0]))
        root.addChild(part(.generateSphere(radius: 0.23), 0xE8C6A5, at: [0, 0.70, 0]))
        let hair = part(.generateSphere(radius: 0.235), 0x493D37, at: [0, 0.79, -0.025])
        hair.scale = [1, 0.60, 1]
        root.addChild(hair)
        for x: Float in [-0.075, 0.075] {
            root.addChild(part(.generateSphere(radius: 0.018), 0x302E30, at: [x, 0.71, 0.214]))
        }
        for (arm, x) in [(leftArm, Float(-0.25)), (rightArm, Float(0.25))] {
            arm.position = [x, 0.43, 0]
            arm.addChild(part(.generateBox(size: [0.15, 0.36, 0.15], cornerRadius: 0.07), 0x5D80AA, at: [0, -0.16, 0]))
            arm.addChild(part(.generateSphere(radius: 0.073), 0xE8C6A5, at: [0, -0.36, 0]))
            root.addChild(arm)
        }
        for (leg, shin, x) in [(leftLeg, leftShin, Float(-0.115)), (rightLeg, rightShin, Float(0.115))] {
            leg.position = [x, 0, 0]
            leg.addChild(part(.generateBox(size: [0.17, 0.32, 0.17], cornerRadius: 0.08), 0x3E4C60, at: [0, -0.15, 0]))
            shin.position = [0, -0.31, 0]
            shin.addChild(part(.generateBox(size: [0.15, 0.31, 0.15], cornerRadius: 0.07), 0x3E4C60, at: [0, -0.15, 0]))
            shin.addChild(part(.generateBox(size: [0.17, 0.10, 0.26], cornerRadius: 0.045), 0xE4E5E4, at: [0, -0.29, 0.055]))
            leg.addChild(shin)
            root.addChild(leg)
        }
        for sign: Float in [-1, 1] {
            let page = part(.generateBox(size: [0.20, 0.025, 0.28], cornerRadius: 0.008), 0xF3EEE2, at: [sign * 0.10, 0, 0])
            page.orientation = simd_quatf(angle: sign * 0.13, axis: [0, 0, 1])
            heldBook.addChild(page)
        }
        heldBook.position = [0, 0.17, 0.37]
        heldBook.orientation = simd_quatf(angle: 0.25, axis: [1, 0, 0])
        heldBook.isEnabled = false
        root.addChild(heldBook)
    }

    var headPosition: SIMD3<Float> { root.position + [0, 1.04, 0] }
    var isWalking: Bool { !route.isEmpty || seatingProgress != nil }

    func setIntent(_ next: Intent, reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        guard next != intent else {
            pendingIntent = nil
            if reduceMotion, isWalking { arrive() }
            return
        }
        if isWalking, !reduceMotion { pendingIntent = next; return }
        pendingIntent = nil
        let wasSeated = seated
        intent = next
        heldBook.isEnabled = false
        if wasSeated && (next == .seated || next == .reading) { arrive(); return }
        if reduceMotion { arrive(); return }
        if wasSeated {
            root.position = approach
            seated = false
            route = [frontSeat, frontLeft, passage, shelf]
        } else {
            route = root.position.z > 0.5 ? [passage, shelf] : [shelf]
        }
        switch next {
        case .shelf: break
        case .window: route.append(window)
        case .seated, .reading: route += [passage, frontLeft, frontSeat, approach]
        }
        applyPose(walk: 0)
    }

    func update(deltaTime: TimeInterval) {
        let delta = Float(min(deltaTime, 0.05))
        if let progress = seatingProgress {
            let next = min(1, progress + delta / 0.45)
            let eased = next * next * (3 - 2 * next)
            root.position = seatingStart + (seat - seatingStart) * eased
            root.orientation = simd_quatf(angle: -0.48, axis: [0, 1, 0])
            applyPose(walk: 0, sitAmount: eased)
            seatingProgress = next
            if next >= 1 { arrive() }
            return
        }
        guard !route.isEmpty else { return }
        let target = route[0]
        let offset = target - root.position
        let distance = simd_length(offset)
        if distance < max(0.025, delta * 1.35) {
            root.position = target
            route.removeFirst()
            if route.isEmpty {
                if (intent == .seated || intent == .reading), !reduceMotion {
                    seatingStart = root.position
                    seatingProgress = 0
                } else { arrive() }
            }
        } else {
            root.position += simd_normalize(offset) * delta * 1.35
            root.orientation = simd_quatf(angle: atan2(offset.x, offset.z), axis: [0, 1, 0])
            phase += delta * 9
            applyPose(walk: sin(phase) * 0.38)
        }
    }

    private func arrive() {
        seatingProgress = nil
        route.removeAll()
        seated = intent == .seated || intent == .reading
        root.position = seated ? seat : (intent == .window ? window : shelf)
        root.orientation = simd_quatf(angle: seated ? -0.48 : 0.25, axis: [0, 1, 0])
        heldBook.isEnabled = intent == .reading
        applyPose(walk: 0)
        if let pending = pendingIntent {
            pendingIntent = nil
            setIntent(pending, reduceMotion: reduceMotion)
        }
    }

    private func applyPose(walk: Float, sitAmount: Float? = nil) {
        let sit = sitAmount ?? (seated ? 1 : 0)
        let reading = intent == .reading && seated
        leftLeg.orientation = simd_quatf(angle: sit > 0 ? -.pi / 2 * sit : walk, axis: [1, 0, 0])
        rightLeg.orientation = simd_quatf(angle: sit > 0 ? -.pi / 2 * sit : -walk, axis: [1, 0, 0])
        let knee = simd_quatf(angle: .pi / 2 * sit, axis: [1, 0, 0])
        leftShin.orientation = knee; rightShin.orientation = knee
        leftArm.orientation = simd_quatf(angle: reading ? -1.02 : -walk, axis: [1, 0, 0])
        rightArm.orientation = simd_quatf(angle: reading ? -1.02 : walk, axis: [1, 0, 0])
    }

    private func part(_ mesh: MeshResource, _ color: UInt32, at position: SIMD3<Float>) -> ModelEntity {
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: UIColor(roomHex: color), roughness: 0.88, isMetallic: false)])
        entity.position = position
        return entity
    }
}
