import RealityKit
import UIKit

/// Geometry, colors and local transforms are exported from the approved room prototype.
@MainActor
final class MiniRoomRealityScene {
    enum Hit { case book(UUID), guestbook, lamp }
    static let shelfCapacity = 9
    static let initialAngle: Float = 0.40
    let anchor = AnchorEntity(world: .zero)
    private let cameraRig = MiniRoomCameraRig()
    private let fill = PointLight()
    private let lamp = PointLight()
    private let daylight = DirectionalLight()
    private var visibleBooks: [Book] = []
    private var bookModels: [UUID: RoomBookEntity] = [:]
    private var focused = true
    private var openedBook: RoomBookEntity?
    private var openingGeneration: UUID?
    private var foregroundDecorations: [Entity] = []
    private var shade: ModelEntity?
    private var lampIsOn: Bool?

    init() {
        anchor.addChild(cameraRig.entity)
        if let url = Bundle.main.url(forResource: "MiniRoomBlueprint", withExtension: "json"),
           let data = try? Data(contentsOf: url), let blueprint = try? JSONDecoder().decode(Node.self, from: data) {
            anchor.addChild(make(blueprint))
        } else {
            assertionFailure("Missing approved mini room blueprint")
        }
        daylight.light.color = UIColor(roomHex: 0xB9CDE6)
        daylight.light.intensity = 260
        daylight.shadow = DirectionalLightComponent.Shadow(maximumDistance: 12, depthBias: 0.1)
        daylight.look(at: [-1.6, 0.5, -1.2], from: [3.5, 5, 1.0], relativeTo: anchor)
        anchor.addChild(daylight)
        fill.light.color = UIColor(roomHex: 0xA7BAD4)
        fill.light.intensity = 140
        fill.position = [-3, 4, 1]
        fill.light.attenuationRadius = 10
        anchor.addChild(fill)
        lamp.position = [-0.22, 1.42, 1.34]
        lamp.light.color = UIColor(roomHex: 0xFFBA6C)
        lamp.light.intensity = 2_200
        lamp.light.attenuationRadius = 7
        anchor.addChild(lamp)
        let floor = ModelEntity(mesh: .generatePlane(width: 28, depth: 28), materials: [
            SimpleMaterial(color: UIColor(roomHex: 0xB78E68), roughness: 0.9, isMetallic: false)
        ])
        floor.position.y = -0.05
        anchor.addChild(floor)
        setLamp(isOn: true)
    }

    func setFocus(_ value: Bool) {
        guard focused != value else { return }
        focused = value
        foregroundDecorations.forEach { $0.isEnabled = !value }
        resetOpenedBook()
        cameraRig.setFocus(value)
    }

    func aimCamera(atAngle angle: Float) {
        cameraRig.orbit(to: angle)
    }

    func updateBooks(_ books: [Book]) {
        guard books != visibleBooks else { return }
        resetOpenedBook()
        visibleBooks = books
        for model in bookModels.values { model.root.removeFromParent() }
        bookModels.removeAll()
        for (i, book) in books.prefix(Self.shelfCapacity).enumerated() {
            let position: SIMD3<Float> = [-2.35 + Float(i % 3) * 0.66, [2.035, 1.12, 0.225][i / 3], -1.21]
            let model = RoomBookEntity(book: book, position: position)
            bookModels[book.id] = model
            anchor.addChild(model.root)
        }
    }

    func openBook(_ id: UUID, reduceMotion: Bool) async -> Bool {
        guard let model = bookModels[id], openedBook == nil else { return false }
        let generation = UUID()
        openingGeneration = generation
        openedBook = model
        defer { if openingGeneration == generation { resetOpenedBook() } }
        if reduceMotion { return true }
        let lifted = cameraRig.presentedBookTransform
        model.root.move(to: lifted, relativeTo: anchor, duration: 0.36, timingFunction: .easeInOut)
        do {
            try await Task.sleep(for: .milliseconds(370))
            guard openingGeneration == generation else { return false }
            var open = model.hinge.transform
            open.rotation = simd_quatf(angle: -.pi * 0.86, axis: [0, 1, 0])
            model.hinge.move(to: open, relativeTo: model.hinge.parent, duration: 0.40, timingFunction: .easeInOut)
            try await Task.sleep(for: .milliseconds(560))
            return !Task.isCancelled && openingGeneration == generation
        } catch { return false }
    }

    func resetOpenedBook() {
        openedBook?.reset()
        openedBook = nil
        openingGeneration = nil
    }

    func hit(at point: CGPoint, in view: ARView) -> Hit? {
        guard let ray = cameraRig.ray(through: point, viewport: view.bounds.size),
              let result = view.scene.raycast(origin: ray.origin, direction: ray.direction, length: 40, query: .nearest).first else { return nil }
        return hit(for: result.entity)
    }

    func hit(for entity: Entity) -> Hit? {
        var current: Entity? = entity
        while let node = current {
            if node.name == "guest" { return .guestbook }
            if node.name == "lamp" { return .lamp }
            if node.name.hasPrefix("book:"), let id = UUID(uuidString: String(node.name.dropFirst(5))) { return .book(id) }
            current = node.parent
        }
        return nil
    }

    func setLamp(isOn: Bool) {
        guard lampIsOn != isOn else { return }
        lampIsOn = isOn
        lamp.isEnabled = isOn
        daylight.light.intensity = 260
        fill.light.intensity = isOn ? 200 : 140
        fill.light.color = UIColor(roomHex: isOn ? 0xEFC99D : 0xA7BAD4)
        shade?.model?.materials = isOn
            ? [UnlitMaterial(color: UIColor(roomHex: 0xE6BB7B))]
            : [SimpleMaterial(color: UIColor(roomHex: 0xD6A75E), roughness: 0.87, isMetallic: false)]
    }

    private struct Node: Decodable {
        var position: [Float]
        var rotation: [Float]
        var scale: [Float]
        var action: String?
        var bookSlot: Int?
        var hideWhenFocused: Bool?
        var shape: String?
        var dimensions: [Float]
        var vertices: [Float]
        var color: UInt32
        var children: [Node]
    }

    private func make(_ node: Node, action: String? = nil) -> Entity {
        let entity: Entity
        let inheritedAction = node.action ?? action
        if let shape = node.shape {
            let mesh: MeshResource
            let d = node.dimensions
            switch shape {
            case "box": mesh = .generateBox(size: [d[0], d[1], d[2]])
            case "cylinder": mesh = taperedCylinder(top: d[0], bottom: d[1], height: d[2], sides: Int(d[3]))
            case "triangle": mesh = triangle(node.vertices)
            case "leaf": mesh = leaf(radius: d[0])
            default: mesh = .generateSphere(radius: d[0])
            }
            let model = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: UIColor(roomHex: node.color), roughness: 0.87, isMetallic: false)])
            if inheritedAction == "lamp", shape == "cylinder", d[0] > 0.14, d[2] > 0.2 { shade = model }
            entity = model
        } else { entity = Entity() }
        entity.name = node.action ?? ""
        entity.position = [node.position[0], node.position[1], node.position[2]]
        entity.scale = [node.scale[0], node.scale[1], node.scale[2]]
        entity.orientation = simd_quatf(angle: node.rotation[0], axis: [1, 0, 0])
            * simd_quatf(angle: node.rotation[1], axis: [0, 1, 0])
            * simd_quatf(angle: node.rotation[2], axis: [0, 0, 1])
        if node.action == "guest", let notebook = externalNotebook() {
            entity.addChild(notebook)
        } else {
            for child in node.children { entity.addChild(make(child, action: inheritedAction)) }
        }
        if node.bookSlot != nil {
            entity.isEnabled = false
        } else if node.action == "guest" || node.action == "lamp" {
            let target = Entity()
            target.name = node.action ?? ""
            let isLamp = node.action == "lamp"
            target.position = isLamp ? [0, 0.59, 0] : [0, 0.08, 0]
            target.components.set(CollisionComponent(shapes: [
                .generateBox(size: isLamp ? [0.60, 0.45, 0.60] : [0.65, 0.22, 0.51])
            ]))
            entity.addChild(target)
        }
        if node.hideWhenFocused == true {
            foregroundDecorations.append(entity)
            entity.isEnabled = !focused
        }
        return entity
    }

    private struct PropPart: Decodable {
        let color: UInt32
        let positions: [[Float]]
    }

    private func externalNotebook() -> Entity? {
        guard let url = Bundle.main.url(forResource: "PolyforkNotebook", withExtension: "json"),
              let data = try? Data(contentsOf: url), let parts = try? JSONDecoder().decode([PropPart].self, from: data) else { return nil }
        let root = Entity()
        for part in parts {
            var mesh = MeshDescriptor(name: "polyfork-notebook")
            mesh.positions = .init(part.positions.map { SIMD3($0[0], $0[1], $0[2]) })
            mesh.primitives = .triangles((0..<part.positions.count).map(UInt32.init))
            guard let resource = try? MeshResource.generate(from: [mesh]) else { continue }
            root.addChild(ModelEntity(mesh: resource, materials: [SimpleMaterial(color: UIColor(roomHex: part.color), roughness: 0.85, isMetallic: false)]))
        }
        return root
    }

    private func leaf(radius: Float) -> MeshResource {
        let t: Float = (1 + sqrt(5)) / 2
        let vertices: [SIMD3<Float>] = [
            [-1,t,0], [1,t,0], [-1,-t,0], [1,-t,0], [0,-1,t], [0,1,t],
            [0,-1,-t], [0,1,-t], [t,0,-1], [t,0,1], [-t,0,-1], [-t,0,1]
        ]
        let faces = [0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11, 1,5,9, 5,11,4,
                     11,10,2, 10,7,6, 7,1,8, 3,9,4, 3,4,2, 3,2,6, 3,6,8,
                     3,8,9, 4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1]
        var positions: [SIMD3<Float>] = []
        for i in stride(from: 0, to: faces.count, by: 3) {
            let a = vertices[faces[i]], b = vertices[faces[i + 1]], c = vertices[faces[i + 2]]
            let ab = (a + b) / 2, bc = (b + c) / 2, ca = (c + a) / 2
            positions += [a,ab,ca, ab,b,bc, ca,bc,c, ab,bc,ca].map { simd_normalize($0) * radius }
        }
        var descriptor = MeshDescriptor(name: "prototype-leaf")
        descriptor.positions = .init(positions)
        descriptor.normals = .init(positions.map { simd_normalize($0) })
        descriptor.primitives = .triangles((0..<positions.count).map(UInt32.init))
        return (try? MeshResource.generate(from: [descriptor])) ?? .generateSphere(radius: radius)
    }

    private func triangle(_ vertices: [Float]) -> MeshResource {
        var descriptor = MeshDescriptor(name: "window-mountain")
        descriptor.positions = .init(stride(from: 0, to: vertices.count, by: 3).map { SIMD3(vertices[$0], vertices[$0 + 1], vertices[$0 + 2]) })
        descriptor.primitives = .triangles([0, 1, 2])
        return (try? MeshResource.generate(from: [descriptor])) ?? .generatePlane(width: 0.1, depth: 0.1)
    }

    private func taperedCylinder(top: Float, bottom: Float, height: Float, sides: Int) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for i in 0..<sides {
            let angle = Float(i) * 2 * .pi / Float(sides)
            positions.append([cos(angle) * bottom, -height / 2, sin(angle) * bottom])
            positions.append([cos(angle) * top, height / 2, sin(angle) * top])
        }
        positions += [[0, -height / 2, 0], [0, height / 2, 0]]
        for i in 0..<sides {
            let a = UInt32(i * 2), b = UInt32((i + 1) % sides * 2), bottomCenter = UInt32(sides * 2)
            indices += [a, a + 1, b, b, a + 1, b + 1, bottomCenter, a, b, bottomCenter + 1, b + 1, a + 1]
        }
        var descriptor = MeshDescriptor(name: "tapered-cylinder")
        descriptor.positions = .init(positions)
        descriptor.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [descriptor])) ?? .generateCylinder(height: height, radius: bottom)
    }
}

extension UIColor {
    convenience init(roomHex: UInt32) {
        self.init(red: CGFloat((roomHex >> 16) & 255) / 255, green: CGFloat((roomHex >> 8) & 255) / 255, blue: CGFloat(roomHex & 255) / 255, alpha: 1)
    }
}
