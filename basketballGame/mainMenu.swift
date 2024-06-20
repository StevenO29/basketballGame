//
//  mainMenu.swift
//  basketballGame
//
//  Created by ayen on 24/05/24.
//

import SwiftUI
import AuthenticationServices
import GameKit

struct mainMenu: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // if iOS
    @StateObject private var game = gameCenter()
    @State private var showSoloAlert = false
    @State private var showMultiplayerAlert = false
    @State private var showLeaderboardAlert = false
    @State private var navigateToContentView = false
    @State private var navigateToMultiplayer = false
    var viewController: UIViewController?
    
    var body: some View {
        if horizontalSizeClass == .compact {
            NavigationView {
                content
            }
        } else {
            NavigationStack {
                content
            }
        }
    }
    
    var content: some View {
        NavigationStack {
            ZStack {
                Image("Wallpaper3")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer().frame(height: 70)
                    Text("AR 3D Basketball")
                        .font(.custom("RichuMastRegular", size: 45))
                        .foregroundColor(.white)
                    Spacer().frame(height: 280) // Menambahkan spacer untuk memposisikan konten lainnya di bawah logo
                    
                    // Tombol pertama: Solo
                    VStack {
                        Button(action: {
                            showSoloAlert = true
                        }) {
                            Text("Solo Player")
                        }
                        .foregroundColor(.whiteColor)
                        .padding()
                        .frame(maxWidth: 290)
                        .background(Color.redColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .font(.custom("RichuMastRegular", size: 30))
                        .alert(isPresented: $showSoloAlert) {
                            Alert(
                                title: Text("Important"),
                                message: Text("Make sure your position does not change and point the camera forward"),
                                dismissButton: .default(Text("Got it!"), action: {
                                    navigateToContentView = true
                                })
                            )
                        }
                        .background(NavigationLink(destination: ContentView(), isActive: $navigateToContentView, label: { EmptyView() }))
                        Spacer().frame(height: 20) // Spacer untuk memberi jarak antar tombol
                        
                        // Tombol kedua: Multi Player
                        Button(action: {
                            showMultiplayerAlert = true
                        }) {
                            Text("Multiplayer")
                        }
                        .foregroundColor(.whiteColor)
                        .padding()
                        .frame(maxWidth: 290)
                        .background(Color.redColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .font(.custom("RichuMastRegular", size: 30))
                        .alert(isPresented: $showMultiplayerAlert) {
                            Alert(
                                title: Text("Important"),
                                message: Text("Multiplayer mode is still under development"),
                                dismissButton: .default(Text("OK"), action: {
                                    navigateToMultiplayer = true
                                })
                            )
                        }
                        .background(NavigationLink(destination: multiplayerView(), isActive: $navigateToMultiplayer, label: { EmptyView() }))
                        Spacer().frame(height: 20) // Spacer untuk memberi jarak antar tombol
                        
                        // Tombol ketiga: Leader Board
                        Button(action: {
                            // Aksi untuk tombol Leader Board
                        }) {
                            Text("LeaderBoard")
                        }
                        .foregroundColor(.whiteColor)
                        .padding()
                        .frame(maxWidth: 290)
                        .background(Color.redColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .font(.custom("RichuMastRegular", size: 30))
                        .alert(isPresented: $showLeaderboardAlert) {
                            Alert(
                                title: Text("Important"),
                                message: Text("Leaderboard is still unavailable"),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                    .offset(y: -125)
                    
                }
                .padding(.top, 50) // Tambahkan padding jika ingin memberikan jarak dari atas layar
                .onAppear{
                    if !game.playingGame {
                        game.authenticatePlayer()
                    }
                }
            }
        }
    }
}

extension Color {
    static let myCustomColor1 = Color(red: 0.10, green: 0.14, blue: 0.25)
    static let myCustomColor2 = Color(red: 0.97, green: 0.87, blue: 0.70)
    static let blackColor = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
    static let whiteColor = Color(red: 0.95, green: 0.95, blue: 0.94) // #f2f2f0
    static let redColor = Color(red: 0.72, green: 0.04, blue: 0.11) // #b7091d
    static let orangeColor = Color(red: 0.90, green: 0.24, blue: 0.0) // #e63e00
}

#Preview {
    mainMenu()
}
