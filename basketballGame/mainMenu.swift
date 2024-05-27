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
    var viewController: UIViewController?
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("Wallpaper")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer().frame(height: 70)
                    Text("AR HOOPS")
                        .font(.custom("SpongeboyMeBob", size: 55))
                        .foregroundColor(.white)
                    Spacer().frame(height: 280) // Menambahkan spacer untuk memposisikan konten lainnya di bawah logo
                    // Tombol pertama: Solo
                    VStack {
                        NavigationLink(destination: ContentView()) {
                            Text("Solo Player")
                        }
                        .foregroundColor(.myCustomColor1)
                        .padding()
                        .frame(maxWidth: 290)
                        .background(Color.myCustomColor2)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .font(.custom("RichuMastRegular", size: 30))
                        Spacer().frame(height: 20) // Spacer untuk memberi jarak antar tombol
                        
                        // Tombol kedua: Multi Player
                        Button(action: {
                            // Aksi untuk tombol Multi Player
                        }) {
                            Text("MultiPlayer")
                            //                            .font(.title)
                            //                            .fontWeight(.bold)
                                .foregroundColor(.myCustomColor1)
                                .padding()
                                .frame(maxWidth: 290)
                                .background(Color.myCustomColor2)
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .font(.custom("RichuMastRegular", size: 30))
                        }
                        
                        Spacer().frame(height: 20) // Spacer untuk memberi jarak antar tombol
                        
                        // Tombol ketiga: Leader Board
                        Button(action: {
                            // Aksi untuk tombol Leader Board
                        }) {
                            Text("LeaderBoard")
                            //                            .font(.title)
                            //                            .fontWeight(.bold)
                                .foregroundColor(.myCustomColor1)
                                .padding()
                                .frame(maxWidth: 290)
                                .background(Color.myCustomColor2)
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .font(.custom("RichuMastRegular", size: 30))
                        }
                    }
                    .offset(y: -125)
                    
                }
                .padding(.top, 50) // Tambahkan padding jika ingin memberikan jarak dari atas layar
                .onAppear{
                    GKLocalPlayer.local.authenticateHandler = { gcAuthVC, error in
                        if GKLocalPlayer.local.isAuthenticated {
                            print("Authenticated to Game Center!")
                            print(GKLocalPlayer.local.teamPlayerID)
                        } else if let vc = gcAuthVC {
                            self.viewController?.present(vc, animated: true)
                        }
                        else {
                            print("Error authentication to GameCenter: " +
                                  "\(error?.localizedDescription ?? "none")")
                        }
                    }
                }
            }
        }
    }
}

extension Color {
    static let myCustomColor1 = Color(red: 0.10, green: 0.14, blue: 0.25)
    static let myCustomColor2 = Color(red: 0.97, green: 0.87, blue: 0.70)
}

#Preview {
    mainMenu()
}
