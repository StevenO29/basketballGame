//
//  gameCenter+GKMatchDelegate.swift
//  basketballGame
//
//  Created by Steven Ongkowidjojo on 04/06/24.
//

import Foundation
import GameKit
import SwiftUI
import ARKit

extension gameCenter: GKMatchDelegate {
    /// Handles a connected, disconnected, or unknown player state.
    /// - Tag:didChange
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            print("\(player.displayName) Connected")
            
            // For automatch, set the opponent and load their avatar.
            if match.expectedPlayerCount == 0 {
                opponent = match.players[0]
                
                // Load the opponent's avatar.
                opponent?.loadPhoto(for: GKPlayer.PhotoSize.small) { (image, error) in
                    if let image {
                        self.opponentAvatar = Image(uiImage: image)
                    }
                    if let error {
                        print("Error: \(error.localizedDescription).")
                    }
                }
            }
        case .disconnected:
            print("\(player.displayName) Disconnected")
        default:
            print("\(player.displayName) Connection Unknown")
        }
    }
    
    /// Handles an error during the matchmaking process.
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        print("\n\nMatch object fails with error: \(error!.localizedDescription)")
    }

    /// Reinvites a player when they disconnect from the match.
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        return false
    }
    
    /// Handles receiving data from other players.
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        // Deserialize the data to ARWorldMap
        if let arWorldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
            // Update the AR session with the received world map
            let configuration = ARWorldTrackingConfiguration()
            configuration.initialWorldMap = arWorldMap
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("Received ARWorldMap from \(player.displayName)")
        }
    }
    
    /// Function to send ARWorldMap to all players
    func sendARWorldMap(_ worldMap: ARWorldMap, to match: GKMatch) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true) {
            do {
                try match.sendData(toAllPlayers: data, with: .reliable)
                print("ARWorldMap sent to all players")
            } catch {
                print("Failed to send ARWorldMap: \(error.localizedDescription)")
            }
        }
    }
}
