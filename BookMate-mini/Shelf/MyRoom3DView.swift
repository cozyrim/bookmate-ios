import SwiftUI
import SceneKit
import Combine

class RoomSceneViewModel: ObservableObject {
    let scene: SCNScene
    let roomNode: SCNNode
    let cameraNode: SCNNode
    
    // 현재 회전 값 보관
    @Published var currentRotationY: Float = .pi / 4 // 기본 45도(대각선 뷰)
    
    init() {
        scene = SCNScene()
        roomNode = SCNNode()
        cameraNode = SCNNode()
        setupScene()
    }
    
    private func setupScene() {
        scene.rootNode.addChildNode(roomNode)
        
        // --- 1. 고퀄리티 PBR(Physically Based Rendering) 머티리얼 설정 ---
        func createPBRMaterial(color: UIColor, roughness: CGFloat = 0.8, metalness: CGFloat = 0.0) -> SCNMaterial {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = color
            material.roughness.contents = NSNumber(value: Float(roughness))
            material.metalness.contents = NSNumber(value: Float(metalness))
            return material
        }
        
        // --- 2. 방 기본 구조 (모서리를 둥글게 처리하여 부드러운 느낌 추가) ---
        // 바닥
        let floor = SCNBox(width: 15, height: 0.5, length: 15, chamferRadius: 0.05)
        floor.firstMaterial = createPBRMaterial(color: UIColor(red: 250/255, green: 235/255, blue: 215/255, alpha: 1.0), roughness: 0.9)
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -0.25, 0)
        roomNode.addChildNode(floorNode)
        
        // 러그 (바닥 위 둥근 원판)
        let rug = SCNCylinder(radius: 3.5, height: 0.05)
        rug.firstMaterial = createPBRMaterial(color: UIColor(red: 220/255, green: 200/255, blue: 180/255, alpha: 1.0), roughness: 1.0)
        let rugNode = SCNNode(geometry: rug)
        rugNode.position = SCNVector3(3.5, 0.02, 3.5)
        roomNode.addChildNode(rugNode)
        
        // 왼쪽 벽
        let leftWall = SCNBox(width: 0.5, height: 10, length: 15, chamferRadius: 0.05)
        leftWall.firstMaterial = createPBRMaterial(color: UIColor(red: 254/255, green: 245/255, blue: 235/255, alpha: 1.0))
        let leftWallNode = SCNNode(geometry: leftWall)
        leftWallNode.position = SCNVector3(-7.5, 5, 0)
        roomNode.addChildNode(leftWallNode)
        
        // 뒷쪽 벽
        let backWall = SCNBox(width: 15, height: 10, length: 0.5, chamferRadius: 0.05)
        backWall.firstMaterial = createPBRMaterial(color: UIColor(red: 245/255, green: 235/255, blue: 225/255, alpha: 1.0))
        let backWallNode = SCNNode(geometry: backWall)
        backWallNode.position = SCNVector3(0, 5, -7.5)
        roomNode.addChildNode(backWallNode)
        
        // 창문 (뒷쪽 벽에 부착)
        let windowFrame = SCNBox(width: 5, height: 4, length: 0.6, chamferRadius: 0.1)
        windowFrame.firstMaterial = createPBRMaterial(color: .white)
        let windowNode = SCNNode(geometry: windowFrame)
        windowNode.position = SCNVector3(-3, 5.5, -7.4)
        
        let glass = SCNBox(width: 4.6, height: 3.6, length: 0.7, chamferRadius: 0)
        glass.firstMaterial = createPBRMaterial(color: UIColor(red: 180/255, green: 220/255, blue: 255/255, alpha: 0.8), roughness: 0.1, metalness: 0.5)
        let glassNode = SCNNode(geometry: glass)
        windowNode.addChildNode(glassNode)
        roomNode.addChildNode(windowNode)
        
        // --- 3. 가구 배치 ---
        // 책장 세부 구현 (프레임과 선반)
        let shelfColor = UIColor(red: 170/255, green: 120/255, blue: 85/255, alpha: 1.0)
        let bookshelfNode = SCNNode()
        bookshelfNode.position = SCNVector3(3.5, 3, -6.0)
        
        let backPanel = SCNBox(width: 6, height: 6, length: 0.2, chamferRadius: 0)
        backPanel.firstMaterial = createPBRMaterial(color: shelfColor)
        let backPanelNode = SCNNode(geometry: backPanel)
        backPanelNode.position = SCNVector3(0, 0, -0.9)
        bookshelfNode.addChildNode(backPanelNode)
        
        for yOffset in [-2.8, -0.9, 1.0, 2.9] { // 선반 층
            let shelf = SCNBox(width: 6, height: 0.2, length: 2, chamferRadius: 0.02)
            shelf.firstMaterial = createPBRMaterial(color: shelfColor)
            let shelfNode = SCNNode(geometry: shelf)
            shelfNode.position = SCNVector3(0, Float(yOffset), 0)
            bookshelfNode.addChildNode(shelfNode)
        }
        roomNode.addChildNode(bookshelfNode)
        
        // 소형 테이블
        let tableTop = SCNCylinder(radius: 1.5, height: 0.2)
        tableTop.firstMaterial = createPBRMaterial(color: .white)
        let tableNode = SCNNode(geometry: tableTop)
        tableNode.position = SCNVector3(-2, 2.1, -1)
        
        let tableLeg = SCNCylinder(radius: 0.15, height: 2.0)
        tableLeg.firstMaterial = createPBRMaterial(color: .lightGray, roughness: 0.3, metalness: 0.8)
        let legNode = SCNNode(geometry: tableLeg)
        legNode.position = SCNVector3(0, -1.0, 0)
        tableNode.addChildNode(legNode)
        roomNode.addChildNode(tableNode)
        
        // --- 4. 책 디테일 추가 ---
        let bookColors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemTeal, .systemIndigo, .systemPink]
        for i in 0..<12 {
            // 다양한 두께와 높이의 책
            let w = Float.random(in: 0.2...0.5)
            let h = Float.random(in: 1.2...1.8)
            let book = SCNBox(width: CGFloat(w), height: CGFloat(h), length: 1.2, chamferRadius: 0.05)
            book.firstMaterial = createPBRMaterial(color: bookColors[i % bookColors.count], roughness: 0.6)
            
            let bookNode = SCNNode(geometry: book)
            let xPos = Float(i % 6) * 0.8 - 2.0 // 선반 내 가로 배치
            let yPos = i < 6 ? Float(-0.1) : Float(1.8) // 1층과 2층
            bookNode.position = SCNVector3(x: xPos, y: yPos, z: -5.8)
            
            // 약간씩 기울어진 책 효과
            bookNode.eulerAngles.z = Float.random(in: -0.1...0.1)
            roomNode.addChildNode(bookNode)
        }
        
        // --- 5. 쿼터뷰(아이소메트릭) 일러스트 느낌의 카메라 설정 ---
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 11
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 18, y: 16, z: 18)
        cameraNode.look(at: SCNVector3(x: 0, y: 3, z: 0))
        scene.rootNode.addChildNode(cameraNode)
        
        // --- 6. 고품질 스튜디오 조명(Lighting) 세팅 ---
        // 환경광 (따뜻한 실내 느낌)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 600
        ambientLight.light?.temperature = 5500
        scene.rootNode.addChildNode(ambientLight)
        
        // 주 광원 (창문에서 들어오는 햇빛 느낌)
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.intensity = 1500
        sunLight.light?.temperature = 6000
        sunLight.light?.castsShadow = true
        sunLight.light?.shadowMode = .deferred
        sunLight.light?.shadowSampleCount = 16 // 부드러운 그림자 경계선
        sunLight.light?.shadowRadius = 3.0
        sunLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.4)
        sunLight.position = SCNVector3(x: -10, y: 20, z: 15)
        sunLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(sunLight)
        
        // 초기 회전값 적용
        roomNode.eulerAngles.y = currentRotationY
    }
    
    // 제스처로 방을 좌우로만 돌리는 함수
    func rotateRoom(by angle: Float) {
        roomNode.eulerAngles.y = currentRotationY + angle
    }
    
    // 제스처가 끝났을 때 현재 회전값 저장
    func finishRotation(by angle: Float) {
        currentRotationY += angle
        roomNode.eulerAngles.y = currentRotationY
    }
    
    // 줌 인/아웃 함수
    func zoom(scale: CGFloat) {
        guard let camera = cameraNode.camera else { return }
        // 기본 12에서 scale에 반비례하도록 설정하여 줌 구현 (범위 제한: 6 ~ 20)
        let newScale = 12.0 / Double(scale)
        camera.orthographicScale = min(max(newScale, 6.0), 20.0)
    }
}

struct MyRoom3DView: View {
    @StateObject private var viewModel = RoomSceneViewModel()
    
    // 제스처 상태 추적
    @GestureState private var dragOffset: CGSize = .zero
    @State private var currentZoom: CGFloat = 1.0
    @GestureState private var zoomState: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack {
                Text("나의 3D 책방")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("좌우로 스와이프하거나 두 손가락으로 줌인 해보세요!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ZStack {
                    // SceneKit 뷰 (기본 조작 꺼둠)
                    SceneView(
                        scene: viewModel.scene,
                        options: [.autoenablesDefaultLighting] // allowsCameraControl 제거
                    )
                    .frame(height: 500)
                    .cornerRadius(20)
                    .padding()
                    .shadow(radius: 10)
                    
                    // 그 위에 투명한 뷰를 덮어 제스처를 받습니다.
                    Color.white.opacity(0.001)
                        .frame(height: 500)
                        .padding()
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation
                                    // 화면을 좌우로 드래그한 만큼 방(Node)을 Y축으로 회전 (비율 조정)
                                    let angle = Float(value.translation.width) * 0.01
                                    DispatchQueue.main.async {
                                        viewModel.rotateRoom(by: angle)
                                    }
                                }
                                .onEnded { value in
                                    let angle = Float(value.translation.width) * 0.01
                                    viewModel.finishRotation(by: angle)
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .updating($zoomState) { value, state, _ in
                                    state = value
                                    DispatchQueue.main.async {
                                        // 현재 줌 배율 * 손가락 배율
                                        viewModel.zoom(scale: currentZoom * value)
                                    }
                                }
                                .onEnded { value in
                                    currentZoom *= value
                                    // 줌 범위 제한 (너무 작아지거나 커지지 않게)
                                    currentZoom = min(max(currentZoom, 0.6), 2.0)
                                    viewModel.zoom(scale: currentZoom)
                                }
                        )
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    MyRoom3DView()
}
