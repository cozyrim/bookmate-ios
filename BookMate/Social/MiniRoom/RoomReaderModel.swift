import RealityKit
import UIKit

/// Original character geometry, separate from movement and reading-session state.
@MainActor
final class RoomReaderModel {
    let root = Entity()
    let leftArm = Entity(), rightArm = Entity()
    let leftLeg = Entity(), rightLeg = Entity()
    let leftShin = Entity(), rightShin = Entity()
    let heldBook = Entity()

    init() {
        root.name = "reader"
        // An original soft bear silhouette: broad head, inset ears and a small muzzle.
        let torso = part(.generateSphere(radius: 0.27), 0x5479B0, at: [0, 0.25, 0])
        torso.scale = [0.92, 1.05, 0.70]
        root.addChild(torso)
        let head = part(.generateSphere(radius: 0.285), 0xD2BCA4, at: [0, 0.74, 0])
        head.scale = [1, 0.94, 0.91]
        root.addChild(head)
        for x: Float in [-0.225, 0.225] {
            root.addChild(part(.generateSphere(radius: 0.09), 0xB49C85, at: [x, 0.945, -0.015]))
            let inset = part(.generateSphere(radius: 0.052), 0xDBC7B2, at: [x, 0.95, 0.054])
            inset.scale.z = 0.35
            root.addChild(inset)
        }
        let muzzle = part(.generateSphere(radius: 0.10), 0xF2E5D2, at: [0, 0.68, 0.233])
        muzzle.scale = [1.12, 0.76, 0.48]
        root.addChild(muzzle)
        let nose = part(.generateSphere(radius: 0.027), 0x443C38, at: [0, 0.705, 0.281])
        nose.scale = [1, 0.7, 0.6]
        root.addChild(nose)
        for x: Float in [-0.095, 0.095] {
            root.addChild(part(.generateSphere(radius: 0.021), 0x343640, at: [x, 0.774, 0.239]))
        }
        let collar = part(.generateCylinder(height: 0.065, radius: 0.14), 0x7795BF, at: [0, 0.51, 0])
        root.addChild(collar)
        for (arm, x) in [(leftArm, Float(-0.25)), (rightArm, Float(0.25))] {
            arm.position = [x, 0.43, 0]
            arm.addChild(part(.generateBox(size: [0.15, 0.36, 0.15], cornerRadius: 0.07), 0x5479B0, at: [0, -0.16, 0]))
            arm.addChild(part(.generateSphere(radius: 0.073), 0xD2BCA4, at: [0, -0.36, 0]))
            root.addChild(arm)
        }
        for (leg, shin, x) in [(leftLeg, leftShin, Float(-0.115)), (rightLeg, rightShin, Float(0.115))] {
            leg.position = [x, 0, 0]
            leg.addChild(part(.generateBox(size: [0.17, 0.32, 0.17], cornerRadius: 0.08), 0x526477, at: [0, -0.15, 0]))
            shin.position = [0, -0.31, 0]
            shin.addChild(part(.generateBox(size: [0.15, 0.31, 0.15], cornerRadius: 0.07), 0x526477, at: [0, -0.15, 0]))
            shin.addChild(part(.generateBox(size: [0.17, 0.10, 0.26], cornerRadius: 0.045), 0xF0F2F3, at: [0, -0.29, 0.055]))
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


    private func part(_ mesh: MeshResource, _ color: UInt32, at position: SIMD3<Float>) -> ModelEntity {
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: UIColor(roomHex: color), roughness: 0.88, isMetallic: false)])
        entity.position = position
        return entity
    }
}
