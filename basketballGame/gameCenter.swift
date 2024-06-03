/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main class that implements the logic for a simple real-time game.
*/

import Foundation
import GameKit
import SwiftUI

/// - Tag:RealTimeGame
@MainActor
class gameCenter: NSObject, GKGameCenterControllerDelegate, ObservableObject {
    
    
    
    
    // The game interface state.
    @Published var matchAvailable = false
    @Published var playingGame = false
    @Published var myMatch: GKMatch? = nil
    @Published var automatch = false
    
    // Outcomes of the game for notifing players.
    @Published var youForfeit = false
    @Published var opponentForfeit = false
    @Published var youWon = false
    @Published var opponentWon = false
    
    // The match information.
    @Published var myAvatar = Image(systemName: "person.crop.circle")
    @Published var opponentAvatar = Image(systemName: "person.crop.circle")
    @Published var opponent: GKPlayer? = nil
    @Published var myScore = 0
    @Published var opponentScore = 0
    
    // The voice chat properties.
    @Published var voiceChat: GKVoiceChat? = nil
    @Published var opponentSpeaking = false
    
    /// The name of the match.
    var matchName: String {
        "\(opponentName) Match"
    }
    
    /// The local player's name.
    var myName: String {
        GKLocalPlayer.local.displayName
    }
    
    /// The opponent's name.
    var opponentName: String {
        opponent?.displayName ?? "Invitation Pending"
    }
    
    /// The root view controller of the window.
    var rootViewController: UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
    
    /// Starts the matchmaking process where GameKit finds a player for the match.
    /// - Tag:findPlayer
    func findPlayer() async {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        let match: GKMatch
        
        // If you use matchmaking rules, set the GKMatchRequest.queueName property here. If the rules use
        // game-specific properties, set the local player's GKMatchRequest.properties too.
        
        // Start automatch.
        do {
            match = try await GKMatchmaker.shared().findMatch(for: request)
        } catch {
            print("Error: \(error.localizedDescription).")
            return
        }

        // Stop automatch.
        GKMatchmaker.shared().finishMatchmaking(for: match)
        automatch = false
    }
    
    /// Presents the matchmaker interface where the local player selects and sends an invitation to another player.
    /// - Tag:choosePlayer
    func choosePlayer() {
        // Create a match request.
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        
        // If you use matchmaking rules, set the GKMatchRequest.queueName property here. If the rules use
        // game-specific properties, set the local player's GKMatchRequest.properties too.
        
        // Present the interface where the player selects opponents and starts the game.
        if let viewController = GKMatchmakerViewController(matchRequest: request) {
            viewController.matchmakerDelegate = self
            rootViewController?.present(viewController, animated: true) { }
        }
    }
    
    // Starting and stopping the game.
    
    /// Saves the local player's score.
    /// - Tag:saveScore
    func saveScore() {
        GKLeaderboard.submitScore(myScore, context: 0, player: GKLocalPlayer.local,
            leaderboardIDs: ["123"]) { error in
            if let error {
                print("Error: \(error.localizedDescription).")
            }
        }
    }
    
    /// Resets a match after players reach an outcome or cancel the game.
    func resetMatch() {
        // Reset the game data.
        playingGame = false
        myMatch?.disconnect()
        myMatch?.delegate = nil
        myMatch = nil
        voiceChat = nil
        opponent = nil
        opponentAvatar = Image(systemName: "person.crop.circle")
        GKAccessPoint.shared.isActive = true
        youForfeit = false
        opponentForfeit = false
        youWon = false
        opponentWon = false
        
        // Reset the score.
        myScore = 0
        opponentScore = 0
    }
    
    // Rewarding players with achievements.
    
    /// Reports the local player's progress toward an achievement.
    func reportProgress() {
        GKAchievement.loadAchievements(completionHandler: { (achievements: [GKAchievement]?, error: Error?) in
            let achievementID = "1234"
            var achievement: GKAchievement? = nil

            // Find an existing achievement.
            achievement = achievements?.first(where: { $0.identifier == achievementID })

            // Otherwise, create a new achievement.
            if achievement == nil {
                achievement = GKAchievement(identifier: achievementID)
            }

            // Create an array containing the achievement.
            let achievementsToReport: [GKAchievement] = [achievement!]

            // Set the progress for the achievement.
            achievement?.percentComplete = achievement!.percentComplete + 10.0

            // Report the progress to Game Center.
            GKAchievement.report(achievementsToReport, withCompletionHandler: {(error: Error?) in
                if let error {
                    print("Error: \(error.localizedDescription).")
                }
            })

            if let error {
                print("Error: \(error.localizedDescription).")
            }
        })
    }
}

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
        gameCenterViewController.dismiss(animated: true)
    }
}

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
}

