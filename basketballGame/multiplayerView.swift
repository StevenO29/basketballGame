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
import Combine

struct multiplayerView: View {
    
    @StateObject private var game = gameCenter()
    @State private var isModelPlaced: Bool = false
    @State var score: Int = 0
    @State var timer: Int = 60
    @State var isShared = false
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
                
                if isShared == false {
                    HStack {
                        Button("Reset", role: .destructive) {
                            ActionManager.shared.actionStream.send(.remove3DModel)
                            isModelPlaced = false
                            timer = 60
                            cancellable?.cancel()
                            isShared = false
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
                                isShared = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                Spacer()
            }
            .onAppear {
                game.choosePlayer()
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
                    self.isShared = false
                }
            }
    }
}

#Preview {
    multiplayerView()
}
