//
//  multiplayerView.swift
//  basketballGame
//
//  Created by Steven Ongkowidjojo on 28/05/24.
//

import SwiftUI
import GameKit
import Foundation

struct multiplayerView: View {
    @StateObject private var game = gameCenter()
    
    var body: some View {
        ContentView()
            .onAppear {
                game.choosePlayer()
            }
    }
}

#Preview {
    multiplayerView()
}
