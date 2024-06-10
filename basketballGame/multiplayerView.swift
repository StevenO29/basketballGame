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
    @State private var isShared: Bool = false
    @State private var timer: Int = 60
    @State private var cancellable: AnyCancellable? = nil
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShared == false {
                HStack {
                    Button(role: .destructive, action: {
                        ActionManager.shared.actionStream.send(.removeAllModels)
                        isModelPlaced = false
                        timer = 60
                        cancellable?.cancel()
                        isShared = false
                    }) {
                        Text("Reset")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isModelPlaced)
                    
                    Button(action: {
                        if isModelPlaced == false {
                            ActionManager.shared.actionStream.send(.place3DModel)
                            isModelPlaced = true
                        } else {
                            startTimer()
                            ActionManager.shared.actionStream.send(.shoot)
                            isShared = true
                        }
                    }) {
                        Text(isModelPlaced ? "Start" : "Place")
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
