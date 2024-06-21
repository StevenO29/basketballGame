//  ContentView.swift
//  basketballGame
//  Created by Steven Ongkowidjojo on 17/05/24.

import SwiftUI
import ARKit
import RealityKit
import FocusEntity
import Combine
import GameKit

struct ContentView : View {
    
    @ObservedObject var basketballManager = BasketballManager.shared
    @State private var isModelPlaced: Bool = false
    @State private var gameStatus = false
    @State private var backToMainMenu = false
    @State var timer: Int = 60
    @State var isStart = false
    @State var cancellable: AnyCancellable? = nil
    
    var body: some View {
        ZStack {
            ARViewContainer().edgesIgnoringSafeArea(.all)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height < 0 && isStart {
                                ActionManager.shared.actionStream.send(.shoot)
                            }
                        }
                )
            VStack {
                HStack {
                    Spacer()
                    Text("Highscore: \(basketballManager.highScore)")
                        .font(.custom("RichuMastRegular", size: 19))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Spacer()
                    
                    Text("Time: \(timer)")
                        .font(.custom("RichuMastRegular", size: 20))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    Text("Score: \(basketballManager.totalScore)")
                        .font(.custom("RichuMastRegular", size: 20))
                        .multilineTextAlignment(.trailing)
                    Spacer()
                    Spacer()
                }
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                
                if isStart == false {
                    HStack {
                        Button("Reset", role: .destructive) {
                            ActionManager.shared.actionStream.send(.removeAllModels)
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
        .alert(isPresented: $gameStatus) {
            Alert(
                title: Text("Time's Up!"),
                message: Text("The game is over. Your score : \(basketballManager.totalScore)"),
                dismissButton: .default(Text("Back to Main Menu"), action: {
                    backToMainMenu = true
                    basketballManager.updateHighScore()
                })
            )
        }
        .background(NavigationLink(destination: mainMenu()
            .navigationBarBackButtonHidden(true)
                                   , isActive: $backToMainMenu, label: { EmptyView() }))
        .onAppear {
            basketballManager.loadHighScore()
            basketballManager.totalScore = 0
            GKAccessPoint.shared.isActive = false
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
                    self.gameStatus = true
                }
            }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> CustomARView {
        return CustomARView(frame: UIScreen.main.bounds)
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) {}
}

class CustomARView: ARView {
    
    @ObservedObject var basketballManager = BasketballManager.shared
    var collisionSubscription: Cancellable?
    var anchorEntity = AnchorEntity()
    var focusEntity: FocusEntity?
    private var cancellables: Set<AnyCancellable> = []
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        setupARView()
        subscribeToActionStream()
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupARView() {
        self.focusEntity = FocusEntity(on: self, style: .classic(color: .yellow))
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        
        self.environment.sceneUnderstanding.options.insert(.occlusion)
        self.session.run(config)
        
        collisionSubscription = scene.publisher(for: CollisionEvents.Began.self, on: nil)
            .sink(receiveValue: onCollisionBegan)
        
        addCoaching()
    }
    
    private func onCollisionBegan(_ event: CollisionEvents.Began) {
        print("Collide!")
        let firstEntity = event.entityA
        let secondEntity = event.entityB
        
        if firstEntity.name == "triggerEntity" && secondEntity.name == "basketballEntity" {
            print("Goal!")
            basketballManager.totalScore += 1
        }
    }
    
    func addBasketHoop() {
        guard let focusEntity = self.focusEntity else { return }
        
        collisionSubscription = scene.publisher(for: CollisionEvents.Began.self, on: nil).sink(receiveValue: onCollisionBegan)
        
        // BOX ENTITY FOR TRIGGER
        let box = MeshResource.generateBox(width: 0.4, height: 0.01, depth: 0.35)
        let material = SimpleMaterial(color: UIColor.clear, isMetallic: false)
        let triggerEntity = ModelEntity(mesh: box, materials: [material])
        
        triggerEntity.collision = CollisionComponent(shapes: [.generateBox(width: 0.4, height: 0.01, depth: 0.35)], mode: .trigger, filter: .sensor)
        triggerEntity.name = "triggerEntity"
        
        let anchorPosition = AnchorEntity(world: focusEntity.position)
        let anchor = AnchorEntity(world: .init(x: focusEntity.position.x, y: focusEntity.position.y + 2.15, z: focusEntity.position.z + 0.96))
        anchor.addChild(triggerEntity)
        
        // BASKET HOOP ENTITY
        let secondAnchor = AnchorEntity(world: focusEntity.position)
        let basketHoopEntity = try! ModelEntity.loadModel(named: "ring4")
        basketHoopEntity.scale = SIMD3<Float>(x: 0.05, y: 0.05, z: 0.05)
        secondAnchor.addChild(basketHoopEntity)
        
        // LEFT RING ENTITY
        let leftRingEntity = ModelEntity(mesh: MeshResource.generateBox(width: 0.02, height: 0.02, depth: 0.5),
                                         materials: [SimpleMaterial(color: UIColor.clear, isMetallic: false)])
        
        leftRingEntity.collision = CollisionComponent(shapes: [.generateBox(width: 0.02, height: 0.02, depth: 0.5)])
        leftRingEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        
        let thirdAnchor = AnchorEntity(world: .init(x: focusEntity.position.x - 0.2, y: focusEntity.position.y + 2.27, z: focusEntity.position.z + 0.9))
        thirdAnchor.addChild(leftRingEntity)
        
        // MIDDLE RING ENTITY
        let middleRingEntity = ModelEntity(mesh: MeshResource.generateBox(width: 0.43, height: 0.02, depth: 0.02),
                                           materials: [SimpleMaterial(color: UIColor.clear, isMetallic: false)])
        
        middleRingEntity.collision = CollisionComponent(shapes: [.generateBox(width: 0.43, height: 0.02, depth: 0.02)])
        middleRingEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        
        let fourthAnchor = AnchorEntity(world: .init(x: focusEntity.position.x, y: focusEntity.position.y + 2.27, z: focusEntity.position.z + 1.15))
        fourthAnchor.addChild(middleRingEntity)
        
        // RIGHT RING ENTITY
        let rightRingEntity = ModelEntity(mesh: MeshResource.generateBox(width: 0.02, height: 0.02, depth: 0.5),
                                          materials: [SimpleMaterial(color: UIColor.clear, isMetallic: false)])
        
        rightRingEntity.collision = CollisionComponent(shapes: [.generateBox(width: 0.02, height: 0.02, depth: 0.5)])
        rightRingEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        
        let fifthAnchor = AnchorEntity(world: .init(x: focusEntity.position.x + 0.2, y: focusEntity.position.y + 2.27, z: focusEntity.position.z + 0.9))
        fifthAnchor.addChild(rightRingEntity)
        
        // BACK HOOP ENTITY
        let backHoopEntity = ModelEntity(mesh: MeshResource.generateBox(width: 1.1, height: 0.73, depth: 0.02),
                                         materials: [SimpleMaterial(color: UIColor.clear, isMetallic: false)])
        
        backHoopEntity.collision = CollisionComponent(shapes: [.generateBox(width: 1.1, height: 0.73, depth: 0.02)])
        backHoopEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        
        let sixthAnchor = AnchorEntity(world: .init(x: focusEntity.position.x, y: focusEntity.position.y + 2.45, z: focusEntity.position.z + 0.63))
        sixthAnchor.addChild(backHoopEntity)
        
        scene.addAnchor(anchor)
        scene.addAnchor(secondAnchor)
        scene.addAnchor(thirdAnchor)
        scene.addAnchor(fourthAnchor)
        scene.addAnchor(fifthAnchor)
        scene.addAnchor(sixthAnchor)
        
        focusEntity.destroy()
    }
    
    func shoot() {
        guard let frame = session.currentFrame else { return }
        let cameraTransform = frame.camera.transform
        
        let sphere = MeshResource.generateSphere(radius: 0.15)
        let material = SimpleMaterial(color: UIColor(.orange), isMetallic: false)
        let entity = ModelEntity(mesh: sphere, materials: [material])
        //        entity = try! ModelEntity.loadModel(named: "try4")
        
        entity.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.15)])
        entity.physicsBody = PhysicsBodyComponent(massProperties: PhysicsMassProperties(mass: 0.65), material: .generate(friction: 0.4, restitution: 0.7), mode: .dynamic)
        entity.name = "basketballEntity"
        
        let anchor = AnchorEntity(world: cameraTransform)
        anchor.addChild(entity)
        self.scene.addAnchor(anchor)
        
        let impulseMagnitude: Float = -3.5
        let impulseVector = SIMD3<Float>(-3, 0.4, impulseMagnitude)
        entity.applyLinearImpulse(impulseVector, relativeTo: entity.parent)
    }
    
    private func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }
    
    func subscribeToActionStream() {
        ActionManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                case .place3DModel:
                    self?.addBasketHoop()
                case .shoot:
                    self?.shoot()
                case .removeAllModels:
                    self?.removeAllModels()
                }
            }
            .store(in: &cancellables)
    }
    
    func removeAllModels() {
        scene.anchors.removeAll()
        self.focusEntity = FocusEntity(on: self, style: .classic(color: .yellow))
        print("All models removed and focus entity reset")
    }
}

extension float4x4 {
    var forward: SIMD3<Float> {
        normalize(SIMD3<Float>(-columns.2.x, -columns.2.y, -columns.2.z))
    }
}

enum Actions {
    case place3DModel
    case shoot
    case removeAllModels
}

class ActionManager {
    static let shared = ActionManager()
    
    private init() { }
    
    var actionStream = PassthroughSubject<Actions, Never>()
}

class BasketballManager: ObservableObject {
    static let shared = BasketballManager()
    @Published var totalScore: Int = 0 {
        didSet {
            if totalScore > highScore {
                highScore = totalScore
                saveHighScore()
            }
        }
    }
    @Published var highScore: Int = 0
    
    private init() {
        loadHighScore()
    }
    
    func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "highScore")
    }
    
    func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "highScore")
    }
    
    func updateHighScore() {
        if totalScore > highScore {
            highScore = totalScore
            saveHighScore()
        }
    }
}

#Preview {
    ContentView()
}
