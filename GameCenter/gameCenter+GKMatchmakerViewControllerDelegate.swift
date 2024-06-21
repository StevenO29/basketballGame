//
//  gameCenter+GKMatchmakerViewControllerDelegate.swift
//  basketballGame
//
//  Created by Steven Ongkowidjojo on 04/06/24.
//

import Foundation
import GameKit
import SwiftUI

extension gameCenter: GKMatchmakerViewControllerDelegate {
    /// Dismisses the matchmaker interface and starts the game when a player accepts an invitation.
    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFind match: GKMatch) {
        // Dismiss the view controller.
        viewController.dismiss(animated: true) { }
    }
    
    /// Dismisses the matchmaker interface when either player cancels matchmaking.
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    /// Reports an error during the matchmaking process.
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        print("\n\nMatchmaker view controller fails with error: \(error.localizedDescription)")
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        // Dismiss the view controller.
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
