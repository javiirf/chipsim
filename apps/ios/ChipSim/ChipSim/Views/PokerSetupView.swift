//
//  PokerSetupView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

struct PokerSetupView: View {
    @StateObject private var game = PokerGame()
    @State private var showGame = false
    @State private var numPlayers = 2
    @State private var playerNames: [String] = ["Player 1", "Player 2"]
    @State private var smallBlind = 5
    @State private var bigBlind = 10
    @State private var selectedBuyIn: Int? = 100
    @State private var customBuyIn: String = ""
    
    let buyInOptions = [20, 50, 100, 200, 500, 1000, 2000, 5000]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Header
                VStack(spacing: Spacing.sm) {
                    Text("Texas Hold'em")
                        .font(.system(size: FontSize.title, weight: .bold))
                        .foregroundColor(AppColors.gold)
                    
                    Text("Chip tracker with strict rules")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(.gray)
                }
                .padding(Spacing.md)
                
                // Number of Players
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Number of Players")
                        .foregroundColor(AppColors.gold)
                        .font(.system(size: FontSize.md, weight: .semibold))
                    
                    Picker("Players", selection: $numPlayers) {
                        ForEach(2...8, id: \.self) { count in
                            Text("\(count) Players\(count == 2 ? " (Heads-Up)" : "")")
                                .tag(count)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: numPlayers) { _, newValue in
                        updatePlayerNames(count: newValue)
                    }
                }
                .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                .cornerRadius(8)
                
                // Player Names
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Player Names")
                        .foregroundColor(.yellow)
                        .font(.system(size: FontSize.md, weight: .semibold))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                        ForEach(0..<numPlayers, id: \.self) { index in
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Player \(index + 1)")
                                    .font(.system(size: FontSize.xs))
                                    .foregroundColor(AppColors.gold)
                                
                                TextField("Player \(index + 1)", text: Binding(
                                    get: { index < playerNames.count ? playerNames[index] : "" },
                                    set: { newValue in
                                        if index < playerNames.count {
                                            playerNames[index] = newValue
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                                .font(.system(size: FontSize.sm))
                            }
                        }
                    }
                }
                .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                .cornerRadius(8)
                
                // Blinds
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Small Blind")
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(.gray)
                        TextField("SB", value: $smallBlind, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .font(.system(size: FontSize.sm))
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Big Blind")
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(.gray)
                        TextField("BB", value: $bigBlind, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .font(.system(size: FontSize.sm))
                    }
                }
                .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                .cornerRadius(8)
                
                // Starting Chips
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Starting chips per player:")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                        ForEach(buyInOptions, id: \.self) { amount in
                            Button(action: {
                                selectedBuyIn = amount
                            }) {
                                Text(amount >= 1000 ? "$\(amount/1000)K" : "$\(amount)")
                                    .font(.system(size: FontSize.sm, weight: .semibold))
                                    .foregroundColor(selectedBuyIn == amount ? .white : AppColors.gold)
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.sm)
                                    .background(selectedBuyIn == amount ? AppColors.gold : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(AppColors.gold, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    
                    HStack(spacing: Spacing.sm) {
                        Text("Custom:")
                            .font(.system(size: FontSize.sm))
                        TextField("Amount", text: $customBuyIn)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .font(.system(size: FontSize.sm))
                        
                        Button("Start") {
                            if let amount = Int(customBuyIn), amount > 0 {
                                startGame(buyIn: amount)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.gold)
                        .controlSize(.small)
                    }
                }
                .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                .cornerRadius(8)
                
                // Start Button
                Button(action: {
                    if let buyIn = selectedBuyIn {
                        startGame(buyIn: buyIn)
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
        .navigationTitle("Poker Setup")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showGame) {
            PokerGameView(game: game)
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
    
    private func startGame(buyIn: Int) {
        // Auto-calculate blinds if not customized
        var sb = smallBlind
        var bb = bigBlind
        
        if sb == 5 && bb == 10 {
            // Auto-calculate based on buy-in
            if buyIn <= 20 {
                sb = 1; bb = 1
            } else if buyIn <= 50 {
                sb = 1; bb = 2
            } else if buyIn <= 100 {
                sb = 1; bb = 2
            } else if buyIn <= 200 {
                sb = 2; bb = 5
            } else if buyIn <= 500 {
                sb = 5; bb = 10
            } else if buyIn <= 1000 {
                sb = 5; bb = 10
            } else if buyIn <= 2000 {
                sb = 10; bb = 20
            } else {
                sb = 25; bb = 50
            }
        }
        
        game.startGame(
            numPlayers: numPlayers,
            buyIn: buyIn,
            playerNames: playerNames,
            sb: sb,
            bb: bb
        )
    }
}

#Preview {
    NavigationView {
        PokerSetupView()
    }
}

