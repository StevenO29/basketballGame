// ContentView.swift
//  basketballGame
//  Created by Steven Ongkowidjojo on 17/05/24.

import SwiftUI
import ARKit
import RealityKit
import FocusEntity
import Combine

struct ContentView : View {
    
    @State private var isModelPlaced: Bool = false
    @State var score: Int = 0
    @State var timer: Int = 60
    @State var isStart = false
    @State var cancellable: AnyCancellable? = nil
    
    var body: some View {
        ZStack {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Text("Score: \(score)")
                        .font(.custom("RichuMastRegular", size: 25))
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    Text("Time: \(timer)")
                        .font(.custom("RichuMastRegular", size: 25))
                    Spacer()
                }
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                
                if isStart == false {
                    HStack {
                        Button("Reset", role: .destructive) {
                            ActionManager.shared.actionStream.send(.remove3DModel)
                            isModelPlaced = false
                            timer = 60
                            cancellable?.cancel()
                            isStart = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!isModelPlaced)
                        
                        Button(isModelPlaced ? "Start" : "Place") {
                            if isModelPlaced == false {
                                ActionManager.shared.actionStream.send(.place3DModel)
                                isModelPlaced = true
                            } else {
                                startTimer()
                                ActionManager.shared.actionStream.send(.placeBasketball)
                                isStart = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    func startTimer() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.timer > 0 {
                    self.timer -= 1
                } else {
                    self.cancellable?.cancel()
                    self.isStart = false
                }
            }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> CustomARView {
        return CustomARView()
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) {}
}

class CustomARView: ARView {
    var focusEntity: FocusEntity?
    var cancellables: Set<AnyCancellable> = []
    var anchorEntity = AnchorEntity()
    var basketballEntity: Entity?
    
    init() {
        super.init(frame: .zero)
        
        subscribeToActionStream()
        self.focusEntity = FocusEntity(on: self, style: .classic(color: .yellow))
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        
        self.environment.sceneUnderstanding.options.insert(.occlusion)
        self.session.run(config)
        
        setupGestures()
    }
    
    func place3DModel() {
        guard let focusEntity = self.focusEntity else { return }
        
        let modelEntity = try! ModelEntity.load(named: "ring4")
        anchorEntity = AnchorEntity(world: focusEntity.position)
        
        let forwardRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        modelEntity.orientation = forwardRotation
        
        anchorEntity.addChild(modelEntity)
        modelEntity.scale = SIMD3<Float>(x: 0.05, y: 0.05, z: 0.05)
        self.scene.addAnchor(anchorEntity)
    }
    
    func placeBasketball() {
        guard let focusEntity = self.focusEntity else { return }
        
        basketballEntity = try! ModelEntity.load(named: "basketballfixed")
        let cameraPosition = self.cameraTransform.translation
        let cameraForwardDirection = self.cameraTransform.matrix.forward
        let offset: Float = 0.5
        basketballEntity?.position = cameraPosition + offset * cameraForwardDirection

        var physics = PhysicsBodyComponent()
        physics.mode = .dynamic
        basketballEntity?.components.set(physics)
        
        anchorEntity = AnchorEntity(world: basketballEntity!.position)
        anchorEntity.addChild(basketballEntity!)
        basketballEntity?.scale = SIMD3<Float>(x: 0.07, y: 0.07, z: 0.07)
        self.scene.addAnchor(anchorEntity)
        
        focusEntity.destroy()
    }
    
    func updateCursorPosition() {
        let cameraTransform: Transform = cameraTransform

        let localCameraPosition: SIMD3<Float> = anchorEntity.convert(position: cameraTransform.translation, from: nil)
        let _: SIMD3<Float> = cameraTransform.matrix.forward
        let finalPosition: SIMD3<Float> = localCameraPosition + 0.75 * 0.05
        
        basketballEntity?.transform.translation = finalPosition
    }
    
    func subscribeToActionStream() {
        ActionManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                case .place3DModel:
                    self?.place3DModel()
                case .placeBasketball:
                    self?.placeBasketball()
                case .remove3DModel:
                    print("Removing 3D model")
                    guard let scene = self?.scene else { return }
                    
                    _ = scene.anchors.filter { anchor in
                        anchor.children.contains { $0.name == "ring4" }
                    }
                    self!.anchorEntity.removeFromParent()
                }
            }
            .store(in: &cancellables)
    }
    
    func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.addGestureRecognizer(panGesture)
        
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUpGesture.direction = .up
        self.addGestureRecognizer(swipeUpGesture)
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        guard let basketballEntity = basketballEntity else { return }
        let translation = gesture.translation(in: gesture.view)
        
        var newPosition = basketballEntity.position
        newPosition.x += Float(translation.x) * 0.001
        newPosition.y -= Float(translation.y) * 0.001
        
        basketballEntity.position = newPosition
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handleSwipeUp(gesture: UISwipeGestureRecognizer) {
        guard let basketballEntity = basketballEntity else { return }
        
        let force: Float = 10.0
        let direction = self.cameraTransform.matrix.forward + SIMD3<Float>(4, 1, 1)
        
        if var physicsMotion = basketballEntity.components[PhysicsMotionComponent.self] as? PhysicsMotionComponent {
                    physicsMotion.linearVelocity = direction * force
                    basketballEntity.components.set(physicsMotion)
                }
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
}

extension float4x4 {
    var forward: SIMD3<Float> {
        normalize(SIMD3<Float>(-columns.2.x, -columns.2.y, -columns.2.z))
    }
}

enum Actions {
    case place3DModel
    case placeBasketball
    case remove3DModel
}

class ActionManager {
    static let shared = ActionManager()
    
    private init() { }
    
    var actionStream = PassthroughSubject<Actions, Never>()
}

#Preview {
    ContentView()
}
