import Foundation
import CoreGraphics
import RealityKit

enum MiniRoomViewpoint: String, CaseIterable {
    case shelf, room, reading, window

    var title: String {
        switch self {
        case .shelf: "책장"
        case .room: "방 전체"
        case .reading: "독서 자리"
        case .window: "창가"
        }
    }
}

/// Camera composition belongs to the renderer, independently of library/navigation state.
@MainActor
final class MiniRoomCameraRig {
    let entity = Entity()
    private(set) var viewpoint: MiniRoomViewpoint = .shelf
    var focused: Bool { viewpoint == .shelf }
    var isTransitioning: Bool { transition != nil }
    private var horizontalFieldOfView: Float = 62
    private struct Transition {
        let start: Transform
        let end: Transform
        let startFOV: Float
        let endFOV: Float
        var elapsed: Float = 0
    }
    private var transition: Transition?
    private var viewport = CGSize.zero
    private var angle: Float = 0.40
    private(set) var zoom: Float = 1

    static func clampedZoom(_ value: Float) -> Float {
        value.isFinite ? min(1.45, max(0.85, value)) : 1
    }

    func setZoom(_ value: Float) {
        let value = Self.clampedZoom(value)
        guard value != zoom else { return }
        zoom = value
        update(animated: isTransitioning)
    }

    init() { update() }

    func setFocus(_ focused: Bool) {
        setViewpoint(focused ? .shelf : .room, animated: false)
    }

    func setViewpoint(_ value: MiniRoomViewpoint, animated: Bool) {
        guard viewpoint != value else {
            if !animated { finishTransition() }
            return
        }
        viewpoint = value
        zoom = 1
        angle = 0.40
        update(animated: animated && viewport.width > 0)
    }

    func advance(deltaTime: TimeInterval) {
        guard var step = transition, deltaTime.isFinite, deltaTime > 0 else { return }
        step.elapsed = min(0.65, step.elapsed + Float(min(deltaTime, 0.1)))
        let fraction = step.elapsed / 0.65
        let eased = fraction * fraction * (3 - 2 * fraction)
        entity.position = step.start.translation + (step.end.translation - step.start.translation) * eased
        entity.orientation = simd_slerp(step.start.rotation, step.end.rotation, eased)
        horizontalFieldOfView = step.startFOV + (step.endFOV - step.startFOV) * eased
        updateLens()
        transition = fraction >= 1 ? nil : step
    }

    func finishTransition() {
        guard let step = transition else { return }
        entity.transform = step.end
        horizontalFieldOfView = step.endFOV
        transition = nil
        updateLens()
    }

    func setViewport(_ size: CGSize) {
        guard size != viewport else { return }
        viewport = size
        update(animated: isTransitioning)
    }

    func orbit(to angle: Float) {
        self.angle = min(0.75, max(0.12, angle))
        update(animated: isTransitioning)
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

    private func updateLens() {
        entity.components.set(PerspectiveCameraComponent(
            near: 0.05, far: 40, fieldOfViewInDegrees: horizontalFieldOfView,
            fieldOfViewOrientation: .horizontal
        ))
    }

    private func update(animated: Bool = false) {
        let previous = entity.transform
        let previousFOV = horizontalFieldOfView
        let target: SIMD3<Float>
        let baseDistance: Float, baseElevation: Float, framing: Float, azimuth: Float, fieldOfView: Float
        switch viewpoint {
        case .shelf:
            target = [-1.5, 1.15, -1.5]
            (baseDistance, baseElevation, framing, azimuth, fieldOfView) = (2.9, 0.8, 0, angle, 62)
        case .room:
            target = [-0.25, 1.35, -0.1]
            (baseDistance, baseElevation, framing, azimuth, fieldOfView) = (7.8, 3.7, 0.24, angle, 54)
        case .reading:
            target = [1.3, 1.4, 0.55]
            (baseDistance, baseElevation, framing, azimuth, fieldOfView) = (3.6, 1.2, 0.18, angle - 0.7, 58)
        case .window:
            target = [0.95, 1.95, -1.65]
            (baseDistance, baseElevation, framing, azimuth, fieldOfView) = (4.1, 1.1, 0.16, angle - 1.0, 58)
        }
        let distance = baseDistance / zoom
        let elevation = baseElevation / zoom
        entity.look(at: target, from: target + [sin(azimuth) * distance, elevation, cos(azimuth) * distance], relativeTo: nil)
        if viewport.width > 0 {
            let aspect = Float(viewport.height / viewport.width)
            let offset = framing * aspect * sqrt(distance * distance + elevation * elevation) * tan(fieldOfView * .pi / 360)
            entity.position -= entity.orientation.act([0, offset, 0])
        }
        if animated {
            transition = Transition(start: previous, end: entity.transform, startFOV: previousFOV, endFOV: fieldOfView)
            entity.transform = previous
        } else {
            transition = nil
            horizontalFieldOfView = fieldOfView
        }
        updateLens()
    }
}
