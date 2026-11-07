import CoreGraphics
import RealityKit

/// Camera composition belongs to the renderer, independently of library/navigation state.
@MainActor
final class MiniRoomCameraRig {
    let entity = Entity()
    private(set) var focused = true
    private var viewport = CGSize.zero
    private var angle: Float = 0.40

    init() { update() }

    func setFocus(_ focused: Bool) {
        self.focused = focused
        update()
    }

    func setViewport(_ size: CGSize) {
        guard size != viewport else { return }
        viewport = size
        update()
    }

    func orbit(to angle: Float) {
        self.angle = min(0.75, max(0.12, angle))
        update()
    }

    var presentedBookTransform: Transform {
        let position = entity.position + entity.orientation.act([0.33, -0.66, -2.5])
        return Transform(scale: SIMD3(repeating: 1.55), rotation: entity.orientation, translation: position)
    }

    // ARView's point helpers use a vertical FOV on the tested non-AR renderer,
    // even when this camera renders with a horizontal FOV. Use the same projection
    // as the visible scene so a tap lands on the object under the finger.
    func ray(through point: CGPoint, viewport: CGSize) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
        guard viewport.width > 0, viewport.height > 0 else { return nil }
        let width = Float(viewport.width), height = Float(viewport.height)
        let halfWidth = tan(horizontalFieldOfView * .pi / 360)
        let local = SIMD3<Float>(
            (2 * Float(point.x) / width - 1) * halfWidth,
            (1 - 2 * Float(point.y) / height) * halfWidth * height / width,
            -1
        )
        return (entity.position(relativeTo: nil), entity.orientation(relativeTo: nil).act(simd_normalize(local)))
    }

    func project(_ world: SIMD3<Float>, viewport: CGSize) -> CGPoint? {
        guard viewport.width > 0, viewport.height > 0 else { return nil }
        let local = entity.orientation(relativeTo: nil).inverse.act(world - entity.position(relativeTo: nil))
        guard local.z < -0.05 else { return nil }
        let halfWidth = tan(horizontalFieldOfView * .pi / 360)
        let x = (local.x / (-local.z * halfWidth) + 1) * Float(viewport.width) / 2
        let y = (1 - local.y / (-local.z * halfWidth * Float(viewport.height / viewport.width))) * Float(viewport.height) / 2
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    private var horizontalFieldOfView: Float { focused ? 62 : 54 }

    private func update() {
        entity.components.set(PerspectiveCameraComponent(
            near: 0.05, far: 40, fieldOfViewInDegrees: horizontalFieldOfView,
            fieldOfViewOrientation: .horizontal
        ))
        let target: SIMD3<Float> = focused ? [-1.5, 1.15, -1.5] : [-0.25, 1.35, -0.1]
        let distance: Float = focused ? 2.9 : 7.8
        let elevation: Float = focused ? 0.8 : 3.7
        entity.look(at: target, from: target + [sin(angle) * distance, elevation, cos(angle) * distance], relativeTo: nil)
        if !focused, viewport.width > 0 {
            // Compose the room above the bottom controls while retaining matching hit projection.
            let aspect = Float(viewport.height / viewport.width)
            let offset = 0.24 * aspect * sqrt(distance * distance + elevation * elevation) * tan(horizontalFieldOfView * .pi / 360)
            entity.position -= entity.orientation.act([0, offset, 0])
        }
    }
}
