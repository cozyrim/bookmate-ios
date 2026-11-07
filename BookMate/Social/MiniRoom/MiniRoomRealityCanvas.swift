import RealityKit
import SwiftUI

struct MiniRoomRealityCanvas: UIViewRepresentable {
    let books: [Book]
    let focused: Bool
    @Binding var opening: UUID?
    let active: Bool
    let lampIsOn: Bool
    let reduceMotion: Bool
    let darkMode: Bool
    let onHit: (MiniRoomRealityScene.Hit) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let coordinator = context.coordinator
        view.scene.addAnchor(coordinator.room.anchor)
        // Render the native scene without camera access.
        view.renderOptions.insert([.disableMotionBlur, .disableDepthOfField, .disableCameraGrain, .disableAREnvironmentLighting])

        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.tap(_:)))
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.pan(_:)))
        pan.delegate = coordinator
        pan.maximumNumberOfTouches = 1
        tap.require(toFail: pan)
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onHit = onHit
        coordinator.reduceMotion = reduceMotion
        coordinator.openingChanged = { opening = $0 }
        coordinator.room.updateBooks(books)
        coordinator.room.setFocus(focused)
        if !active { coordinator.cancel() }
        else if let opening, coordinator.openingID != opening { coordinator.open(opening) }
        coordinator.room.setLamp(isOn: lampIsOn)
        view.environment.lighting.intensityExponent = lampIsOn ? -1.5 : -3.8
        view.environment.background = .color(darkMode ? UIColor(roomHex: 0x343A46) : UIColor(roomHex: 0xD4CBC0))
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.cancel()
        view.scene.anchors.removeAll()
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let room = MiniRoomRealityScene()
        var onHit: ((MiniRoomRealityScene.Hit) -> Void)?
        var reduceMotion = false
        var openingChanged: ((UUID?) -> Void)?
        var openingID: UUID?
        var openingTask: Task<Void, Never>?
        private var openingGeneration = UUID()

        func cancel() {
            openingGeneration = UUID()
            openingTask?.cancel()
            openingTask = nil
            openingID = nil
            room.resetOpenedBook()
        }

        func open(_ id: UUID) {
            guard openingID == nil else { return }
            let generation = UUID()
            openingGeneration = generation
            openingID = id
            openingChanged?(id)
            openingTask = Task { [weak self] in
                guard let self else { return }
                let completed = await room.openBook(id, reduceMotion: reduceMotion)
                guard generation == openingGeneration else { return }
                if completed && !Task.isCancelled { onHit?(.book(id)) }
                openingID = nil
                openingChanged?(nil)
            }
        }
        private var angle: Float = MiniRoomRealityScene.initialAngle
        private var angleBeforePan: Float = MiniRoomRealityScene.initialAngle

        @objc func tap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? ARView,
                  let hit = room.hit(at: gesture.location(in: view), in: view) else { return }
            guard openingID == nil else { return }
            if case .book(let id) = hit { open(id) } else { onHit?(hit) }
        }

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began { angleBeforePan = angle }
            guard gesture.state == .began || gesture.state == .changed else { return }
            angle = min(0.75, max(0.12, angleBeforePan - Float(gesture.translation(in: gesture.view).x) / 420))
            room.aimCamera(atAngle: angle)
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard openingID == nil, !reduceMotion, let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
