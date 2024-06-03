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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onAppear {
                game.choosePlayer()
            }
    }
}

#Preview {
    multiplayerView()
}
