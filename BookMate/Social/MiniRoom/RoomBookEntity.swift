import RealityKit
import UIKit
import Kingfisher

/// A real library book with a hinged front cover and separately modelled pages.
@MainActor
final class RoomBookEntity {
    let root = Entity()
    private let bookBody = Entity()
    let hinge = Entity()
    private let front: ModelEntity
    private let back: ModelEntity
    let home: Transform

    init(book: Book, position: SIMD3<Float>) {
        root.name = "book:\(book.id)"
        root.position = position
        home = root.transform
        root.addChild(bookBody)
        let paper = SimpleMaterial(color: UIColor(roomHex: 0xF2E4C9), roughness: 0.9, isMetallic: false)
        let pages = ModelEntity(mesh: .generateBox(size: [0.51, 0.70, 0.10], cornerRadius: 0.006), materials: [paper])
        pages.position = [0, 0.36, -0.06]
        bookBody.addChild(pages)
        let backing = ModelEntity(mesh: .generateBox(size: [0.55, 0.74, 0.015]), materials: [SimpleMaterial(color: UIColor(roomHex: 0x6A715C), roughness: 0.8, isMetallic: false)])
        backing.position = [0, 0.37, -0.12]
        bookBody.addChild(backing)
        hinge.position = [-0.275, 0.37, 0]
        bookBody.addChild(hinge)
        front = Self.panel(width: 0.55, height: 0.74)
        front.position = [0.275, 0, 0.009]
        hinge.addChild(front)
        back = Self.panel(width: 0.55, height: 0.74)
        back.position = [0.275, 0, -0.009]
        back.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        hinge.addChild(back)
        let inside = Self.labelImage(title: book.title, subtitle: "나의 독서 기록", background: 0xF2E4C9)
        Self.apply(inside, to: back)
        let titlePage = Self.panel(width: 0.50, height: 0.69)
        titlePage.position = [0, 0.36, -0.004]
        Self.apply(inside, to: titlePage)
        bookBody.addChild(titlePage)
        let fallback = Self.labelImage(title: book.title, subtitle: book.author, background: 0xD9C7A6)
        Self.apply(fallback, to: front)
        let target = Entity()
        target.position = [0, 0.37, -0.04]
        target.components.set(CollisionComponent(shapes: [.generateBox(size: [0.57, 0.76, 0.18])]))
        bookBody.addChild(target)
        if !book.imageName.hasPrefix("http"), let image = UIImage(named: book.imageName) {
            applyCover(image)
        } else if let url = URL(string: book.imageName), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
            KingfisherManager.shared.retrieveImage(with: BookCoverSource.preferredURL(for: url), options: [.processor(DownsamplingImageProcessor(size: CGSize(width: 512, height: 720))), .alternativeSources(BookCoverSource.preferredURL(for: url) == url ? [] : [.network(ImageResource(downloadURL: url))])]) { [weak self] result in
                Task { @MainActor in
                    guard let self, case .success(let value) = result else { return }
                    self.applyCover(value.image)
                }
            }
        }
    }

    private func applyCover(_ image: UIImage) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        // Preserve square/wide book formats instead of stretching the source into a novel cover.
        let ratio = Float(image.size.height / image.size.width)
        bookBody.scale.y = min(1, 0.55 * ratio / 0.74)
        bookBody.scale.x = min(1, 0.74 / ratio / 0.55)
        Self.apply(image, to: front)
    }

    func reset() {
        root.stopAllAnimations(recursive: true)
        root.transform = home
        hinge.orientation = simd_quatf()
    }

    private static func panel(width: Float, height: Float) -> ModelEntity {
        var mesh = MeshDescriptor(name: "book-cover")
        mesh.positions = .init([[-width/2,-height/2,0],[width/2,-height/2,0],[width/2,height/2,0],[-width/2,height/2,0]])
        mesh.textureCoordinates = .init([[0,0],[1,0],[1,1],[0,1]])
        mesh.primitives = .triangles([0,1,2,0,2,3])
        return ModelEntity(mesh: (try? MeshResource.generate(from: [mesh])) ?? .generateBox(size: 0.01), materials: [UnlitMaterial(color: .white)])
    }

    private static func apply(_ image: UIImage, to entity: ModelEntity) {
        guard let cg = image.cgImage,
              let texture = try? TextureResource.generate(from: cg, options: .init(semantic: .color)) else { return }
        var material = SimpleMaterial(color: .white, roughness: 0.85, isMetallic: false)
        material.color = .init(tint: .white, texture: .init(texture))
        entity.model?.materials = [material]
    }

    private static func labelImage(title: String, subtitle: String, background: UInt32) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 360), format: format).image { context in
            UIColor(roomHex: background).setFill(); context.fill(CGRect(x: 0, y: 0, width: 256, height: 360))
            let style = NSMutableParagraphStyle(); style.alignment = .center
            (title as NSString).draw(in: CGRect(x: 20, y: 85, width: 216, height: 180), withAttributes: [.font: UIFont.systemFont(ofSize: 25, weight: .semibold), .foregroundColor: UIColor(roomHex: 0x42382C), .paragraphStyle: style])
            (subtitle as NSString).draw(in: CGRect(x: 18, y: 282, width: 220, height: 60), withAttributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor(roomHex: 0x615445), .paragraphStyle: style])
        }
    }
}
