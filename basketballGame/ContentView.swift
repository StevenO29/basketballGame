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
    @State private var buttonEnabled = true
    
    var body: some View {
        ZStack {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                
                Button(buttonEnabled ? "Place" : "Start") {
                    ActionManager.shared.actionStream.send(.place3DModel)
                    buttonEnabled.toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!buttonEnabled)
                
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
        
        self.session.run(config)
    }

    
    func place3DModel() {
        guard let focusEntity = self.focusEntity else { return }

        let modelEntity = try! ModelEntity.load(named: "ring4") // Replace with your asset name
        let anchorEntity = AnchorEntity(world: focusEntity.position)
        anchorEntity.addChild(modelEntity)
        modelEntity.scale = SIMD3<Float>(x: 0.05, y: 0.05, z: 0.05) // Fixed syntax here
        self.scene.addAnchor(anchorEntity)
    }

    
    
    func subscribeToActionStream() {
        ActionManager.shared
            .actionStream
            .sink { [weak self] action in
                
                switch action {
                    
                case .place3DModel:
                    self?.place3DModel()
                    
                case .remove3DModel:
                    print("Removeing 3D model: has not been implemented")
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

enum Actions {
    case place3DModel
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
