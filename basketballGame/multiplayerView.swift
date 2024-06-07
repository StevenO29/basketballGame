//
//  multiplayerView.swift
//  basketballGame
//
//  Created by Steven Ongkowidjojo on 28/05/24.
//

import SwiftUI
import GameKit
import Foundation
import MultipeerConnectivity
import ARKit
import RealityKit

struct multiplayerView: View {
    
    @StateObject private var game = gameCenter()
    @State private var isModelPlaced: Bool = false
    @State var score: Int = 0
    @State var timer: Int = 60
    @State var isShare = false
    @State var sceneView: ARSCNView!
    
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
                
                if isShare == false {
                    HStack {
                        Button("Reset", role: .destructive) {
                            ActionManager.shared.actionStream.send(.remove3DModel)
                            isModelPlaced = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!isModelPlaced)
                        
                        Button(isModelPlaced ? "Share" : "Place") {
                            if isModelPlaced == false {
                                ActionManager.shared.actionStream.send(.place3DModel)
                            }
                            if isModelPlaced == true {
                                isShare = true
                                
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

#Preview {
    multiplayerView()
}
