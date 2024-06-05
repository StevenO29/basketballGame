//
//  ContentView.swift
//  basketballGame
//
//  Created by Steven Ongkowidjojo on 17/05/24.
//

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
                
                if isStart == false{
                    HStack {
                        Button("Reset", role: .destructive) {
                            ActionManager.shared.actionStream.send(.remove3DModel)
                            isModelPlaced = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!isModelPlaced) // Disable the button if the model is not placed
                        
                        Button(isModelPlaced ? "Start" : "Place") {
                            if isModelPlaced == false {
                                ActionManager.shared.actionStream.send(.place3DModel)
                            }
                            if isModelPlaced == true {
                                isStart = true
                                ActionManager.shared.actionStream.send(.placeBasketball)
                               
                            }
                            isModelPlaced = true

                            
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                Spacer()
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
        
        // ActionStrean
        subscribeToActionStream()
        
        // FocusEntity
        self.focusEntity = FocusEntity(on: self, style: .classic(color: .yellow))
        
        // Configuration
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        
        self.environment.sceneUnderstanding.options.insert(.occlusion)

        
        self.session.run(config)
    }
    
    func place3DModel() {
        guard let focusEntity = self.focusEntity else { return }
        
        let modelEntity = try! ModelEntity.load(named: "ring4") // Replace with your asset name
        anchorEntity = AnchorEntity(world: focusEntity.position)
        
//        modelEntity.orientation = self.cameraTransform.rotation
        
        anchorEntity.addChild(modelEntity)
        modelEntity.scale = SIMD3<Float>(x: 0.05, y: 0.05, z: 0.05) // Fixed syntax here
        self.scene.addAnchor(anchorEntity)

    }
    
    func placeBasketball() {
        guard let focusEntity = self.focusEntity else { return }
        
        basketballEntity = try! ModelEntity.load(named: "basketballfixed") // Replace with your asset name
        anchorEntity = AnchorEntity(world: focusEntity.position)
        
        let cameraPosition = self.cameraTransform.translation
        let cameraForwardDirection = self.cameraTransform.matrix.forward
        let offset: Float = 0.5
        basketballEntity?.position = cameraPosition + offset * cameraForwardDirection
        
        anchorEntity.addChild(basketballEntity!)
        basketballEntity?.scale = SIMD3<Float>(x: 0.05, y: 0.05, z: 0.05) // Fixed syntax here
        self.scene.addAnchor(anchorEntity)
        
        focusEntity.destroy()
    }
    
    func updateCursorPosition() {

        let cameraTransform: Transform = cameraTransform

        // 1. Calculate the local camera position, relative to the sceneEntity
        let localCameraPosition: SIMD3<Float> = anchorEntity.convert(position: cameraTransform.translation, from: nil)

        // 2. Get the forward-facing directional vector of the camera using the extension described above
        let _: SIMD3<Float> = cameraTransform.matrix.forward

        // 3. Calculate the final local position of the cursor using distanceFromCamera
        let finalPosition: SIMD3<Float> = localCameraPosition + 0.75 * 0.05
        
        // 4. Apply the translation
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
                    
                    // Find all anchors with the name "ring4"
                    _ = scene.anchors.filter { anchor in
                        anchor.children.contains { $0.name == "ring4" }
                    }
                    
                    // Remove found anchors
                    self!.anchorEntity.removeFromParent()
                }
            }
            .store(in: &cancellables)
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
