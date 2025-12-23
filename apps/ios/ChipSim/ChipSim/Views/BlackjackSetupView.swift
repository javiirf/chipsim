//
//  BlackjackSetupView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

struct BlackjackSetupView: View {
    @StateObject private var game = BlackjackGame()
    @State private var showGame = false
    @State private var selectedMode: BlackjackMode = .single
    @State private var startingBankroll: String = "1000"
    @State private var playerNames: [String] = ["Player 1", "Player 2"]
    @State private var numPlayers = 2
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Header
                VStack(spacing: Spacing.sm) {
                    Text("Blackjack")
                        .font(.system(size: FontSize.title, weight: .bold))
                        .foregroundColor(AppColors.gold)
                    
                    Text("Classic 21")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(.gray)
                }
                .padding(Spacing.md)
                
                // Game Mode Selection
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Game Mode")
                        .foregroundColor(AppColors.gold)
                        .font(.system(size: FontSize.md, weight: .semibold))
                    
                    Picker("Mode", selection: $selectedMode) {
                        Text("Single Player").tag(BlackjackMode.single)
                        Text("Two Hands").tag(BlackjackMode.twoHands)
                        Text("Multiplayer").tag(BlackjackMode.multiplayer)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedMode) { _, newMode in
                        if newMode == .multiplayer {
                            numPlayers = 2
                        }
                    }
                }
                .padding(Spacing.md)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                .cornerRadius(8)
                
                // Starting Bankroll
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Starting Bankroll")
                        .foregroundColor(AppColors.gold)
                        .font(.system(size: FontSize.md, weight: .semibold))
                    
                    TextField("Amount", text: $startingBankroll)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.system(size: FontSize.sm))
                }
                .padding(Spacing.md)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                .cornerRadius(8)
                
                // Multiplayer Player Names
                if selectedMode == .multiplayer {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Number of Players")
                            .foregroundColor(AppColors.gold)
                            .font(.system(size: FontSize.md, weight: .semibold))
                        
                        Picker("Players", selection: $numPlayers) {
                            ForEach(2...7, id: \.self) { count in
                                Text("\(count) Players").tag(count)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: numPlayers) { _, newValue in
                            updatePlayerNames(count: newValue)
                        }
                        
                        Text("Player Names")
                            .foregroundColor(AppColors.gold)
                            .font(.system(size: FontSize.md, weight: .semibold))
                            .padding(.top, Spacing.sm)
                        
                        ForEach(0..<numPlayers, id: \.self) { index in
                            TextField("Player \(index + 1)", text: Binding(
                                get: { index < playerNames.count ? playerNames[index] : "" },
                                set: { newValue in
                                    if index < playerNames.count {
                                        playerNames[index] = newValue
                                    }
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: FontSize.sm))
                        }
                    }
                    .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                }
                
                // Start Button
                Button(action: {
                    if let bankroll = Int(startingBankroll), bankroll > 0 {
                        if selectedMode == .multiplayer {
                            game.startGame(
                                mode: .multiplayer,
                                startingBankroll: bankroll,
                                playerNames: Array(playerNames.prefix(numPlayers))
                            )
                        } else {
                            game.startGame(
                                mode: selectedMode,
                                startingBankroll: bankroll
                            )
                        }
                    }
                }) {
                    Text("Start Game")
                        .font(.system(size: FontSize.lg, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(AppColors.gold)
                        .cornerRadius(10)
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(Spacing.md)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.29, blue: 0.05),
                    Color(red: 0.02, green: 0.19, blue: 0.02)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Blackjack Setup")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showGame) {
            BlackjackGameView(game: game)
        }
        .onChange(of: game.gameStarted) { _, newValue in
            if newValue {
                showGame = true
            }
        }
    }
    
    private func updatePlayerNames(count: Int) {
        while playerNames.count < count {
            playerNames.append("Player \(playerNames.count + 1)")
        }
        playerNames = Array(playerNames.prefix(count))
    }
}

#Preview {
    NavigationView {
        BlackjackSetupView()
    }
}

