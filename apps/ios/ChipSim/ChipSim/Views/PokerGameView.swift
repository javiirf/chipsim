//
//  PokerGameView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI
import UIKit

struct PokerGameView: View {
    @ObservedObject var game: PokerGame
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 400
            
            // Handle special states first
            if game.burnCardPending {
                burnCardView(isSmallScreen: isSmallScreen)
            } else if game.phase == .result, let result = game.lastResult {
                resultView(result: result, isSmallScreen: isSmallScreen)
            } else if game.phase == .showdown {
                showdownView(isSmallScreen: isSmallScreen)
            } else if game.phase == .betting && game.activePlayerIndex < game.players.count {
                // Main 5-column gameplay layout
                bettingLayoutView(geometry: geometry, isSmallScreen: isSmallScreen)
            } else {
                Text("Game Setup")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppColors.feltGreen)
        .onAppear {
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
        .onDisappear {
            AppDelegate.orientationLock = .all
        }
    }
    
    // MARK: - Main Betting Layout (5-column design)
    @ViewBuilder
    private func bettingLayoutView(geometry: GeometryProxy, isSmallScreen: Bool) -> some View {
        let activePlayer = game.players[game.activePlayerIndex]
        let toCall = max(0, game.currentBet - activePlayer.bet)
        let raises = game.getValidRaises()
        
        HStack(spacing: isSmallScreen ? 8 : 12) {
            // COLUMN 1: Action Buttons (Fold, Call/Check, Raise/All-In)
            VStack(spacing: isSmallScreen ? 8 : 12) {
                Text("\(activePlayer.name)'s Turn")
                    .font(.system(size: isSmallScreen ? 14 : 18, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.bottom, isSmallScreen ? 4 : 8)
                
                Button("FOLD") {
                    game.fold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .font(.system(size: isSmallScreen ? 20 : 28, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                
                if toCall > 0 {
                    Button("CALL") {
                        game.call()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .font(.system(size: isSmallScreen ? 20 : 28, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                } else {
                    Button("CHECK") {
                        game.check()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.system(size: isSmallScreen ? 20 : 28, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
                
                if activePlayer.bankroll > 0 && toCall < activePlayer.bankroll && !raises.isEmpty {
                    Button("RAISE") {
                        // Use minimum raise if available
                        if let firstRaise = raises.first {
                            game.raise(to: firstRaise.amount)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: isSmallScreen ? 20 : 28, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                } else if activePlayer.bankroll > 0 {
                    Button("ALL-IN") {
                        game.allIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: isSmallScreen ? 20 : 28, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(width: geometry.size.width * 0.18)
            
            // COLUMN 2: Hole Cards + Raise Chips
            VStack(spacing: isSmallScreen ? 8 : 12) {
                // Hole Cards (2 boxes)
                VStack(spacing: isSmallScreen ? 6 : 8) {
                    Text("HOLE CARDS")
                        .font(.system(size: isSmallScreen ? 10 : 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: isSmallScreen ? 6 : 8) {
                        HoleCardView(isSmallScreen: isSmallScreen)
                        HoleCardView(isSmallScreen: isSmallScreen)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Raise Chips (circular buttons stacked vertically)
                VStack(spacing: isSmallScreen ? 6 : 8) {
                    Text("RAISE AMOUNT")
                        .font(.system(size: isSmallScreen ? 10 : 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ScrollView {
                        VStack(spacing: isSmallScreen ? 8 : 10) {
                            ForEach(Array(raises.prefix(5).enumerated()), id: \.offset) { index, raise in
                                Button(action: {
                                    game.raise(to: raise.amount)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(getChipGradient(raise.chipColor))
                                            .overlay(
                                                Circle()
                                                    .stroke(getChipBorderColor(raise.chipColor), lineWidth: isSmallScreen ? 3 : 4)
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        
                                        VStack(spacing: 2) {
                                            Text(raise.label)
                                                .font(.system(size: isSmallScreen ? 12 : 16, weight: .bold))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            Text("$\(raise.amount)")
                                                .font(.system(size: isSmallScreen ? 14 : 18, weight: .bold))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .foregroundColor(getChipTextColor(raise.chipColor))
                                    }
                                    .frame(width: isSmallScreen ? 70 : 90, height: isSmallScreen ? 70 : 90)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width * 0.22)
            
            // COLUMN 3: Player Stack + Minimum Bet
            VStack(spacing: isSmallScreen ? 12 : 16) {
                VStack(spacing: isSmallScreen ? 4 : 6) {
                    Text("PLAYER")
                        .font(.system(size: isSmallScreen ? 10 : 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text("$\(activePlayer.bankroll)")
                        .font(.system(size: isSmallScreen ? 24 : 32, weight: .bold))
                        .foregroundColor(AppColors.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                VStack(spacing: isSmallScreen ? 4 : 6) {
                    Text("MIN.")
                        .font(.system(size: isSmallScreen ? 10 : 12))
                        .foregroundColor(.white.opacity(0.7))
                    if toCall > 0 {
                        Text("$\(toCall)")
                            .font(.system(size: isSmallScreen ? 18 : 24, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("$0")
                            .font(.system(size: isSmallScreen ? 18 : 24, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.15)
            .padding(.top, isSmallScreen ? 16 : 24)
            
            // COLUMN 4: Community Cards
            VStack(spacing: isSmallScreen ? 8 : 12) {
                Text("COMMUNITY CARDS")
                    .font(.system(size: isSmallScreen ? 14 : 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, isSmallScreen ? 4 : 8)
                
                VStack(spacing: isSmallScreen ? 6 : 8) {
                    ForEach(0..<5) { index in
                        CardSlotView(
                            isDealt: getCardSlotDealt(index: index),
                            isSmallScreen: isSmallScreen
                        )
                        .frame(height: isSmallScreen ? 50 : 65)
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.20)
            .padding(.top, isSmallScreen ? 16 : 24)
            
            // COLUMN 5: Undo All-in, Pot, End
            VStack(spacing: isSmallScreen ? 12 : 16) {
                if game.canUndo {
                    Button("UNDO\nALL-IN") {
                        game.undo()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: isSmallScreen ? 60 : 80)
                    .multilineTextAlignment(.center)
                } else {
                    Spacer()
                        .frame(height: isSmallScreen ? 60 : 80)
                }
                
                VStack(spacing: isSmallScreen ? 4 : 6) {
                    Text("POT")
                        .font(.system(size: isSmallScreen ? 14 : 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("$\(game.pot + game.players.reduce(0) { $0 + $1.bet })")
                        .font(.system(size: isSmallScreen ? 24 : 32, weight: .bold))
                        .foregroundColor(AppColors.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(isSmallScreen ? 12 : 16)
                .frame(maxWidth: .infinity)
                .background(AppColors.gold.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.gold.opacity(0.5), lineWidth: 2)
                )
                
                Button("END") {
                    game.resetGame()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .font(.system(size: isSmallScreen ? 16 : 20, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: isSmallScreen ? 50 : 60)
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.20)
            .padding(.top, isSmallScreen ? 16 : 24)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .padding(isSmallScreen ? 8 : 12)
    }
    
    // MARK: - Supporting Views
    @ViewBuilder
    private func burnCardView(isSmallScreen: Bool) -> some View {
        VStack(spacing: isSmallScreen ? 16 : 24) {
            Text("BURN & DEAL")
                .font(.system(size: isSmallScreen ? 24 : 32, weight: .bold))
                .foregroundColor(AppColors.gold)
            
            Button("Done") {
                game.acknowledgeBurnCard()
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            .font(.system(size: isSmallScreen ? 18 : 24, weight: .semibold))
            .padding(isSmallScreen ? 16 : 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func resultView(result: PokerLastResult, isSmallScreen: Bool) -> some View {
        VStack(spacing: isSmallScreen ? 16 : 24) {
            Text(result.message)
                .font(.system(size: isSmallScreen ? 20 : 28, weight: .bold))
                .foregroundColor(AppColors.gold)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Deal Next Hand") {
                game.newRound()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.gold)
            .font(.system(size: isSmallScreen ? 18 : 24, weight: .semibold))
            .padding(isSmallScreen ? 16 : 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func showdownView(isSmallScreen: Bool) -> some View {
        VStack(spacing: isSmallScreen ? 12 : 16) {
            Text("SHOWDOWN")
                .font(.system(size: isSmallScreen ? 24 : 32, weight: .bold))
                .foregroundColor(AppColors.gold)
                .padding()
            
            ScrollView {
                VStack(spacing: isSmallScreen ? 8 : 12) {
                    ForEach(Array(game.getActivePlayers().enumerated()), id: \.element.id) { index, player in
                        if let playerIndex = game.players.firstIndex(where: { $0.id == player.id }) {
                            Button("\(player.name) Wins") {
                                game.declareWinner(playerIndex)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.gold)
                            .font(.system(size: isSmallScreen ? 16 : 20, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: isSmallScreen ? 50 : 60)
                        }
                    }
                    
                    Button("Split Pot") {
                        game.declareWinner(nil)
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: isSmallScreen ? 16 : 20, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: isSmallScreen ? 50 : 60)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func getCardSlotDealt(index: Int) -> Bool {
        let streetCards: [PokerStreet: Int] = [.preflop: 0, .flop: 3, .turn: 4, .river: 5]
        let revealedCount = game.burnCardPending ? streetCards[getStreetBefore(game.street)] ?? 0 : streetCards[game.street] ?? 0
        return index < revealedCount
    }
    
    private func getStreetBefore(_ street: PokerStreet) -> PokerStreet {
        let order: [PokerStreet] = [.preflop, .flop, .turn, .river]
        if let idx = order.firstIndex(of: street), idx > 0 {
            return order[idx - 1]
        }
        return .preflop
    }
    
    // MARK: - Helper Functions
    
    private func getCardSlotDealt(index: Int) -> Bool {
        let streetCards: [PokerStreet: Int] = [.preflop: 0, .flop: 3, .turn: 4, .river: 5]
        let revealedCount = game.burnCardPending ? streetCards[getStreetBefore(game.street)] ?? 0 : streetCards[game.street] ?? 0
        return index < revealedCount
    }
    
    private func getStreetBefore(_ street: PokerStreet) -> PokerStreet {
        let order: [PokerStreet] = [.preflop, .flop, .turn, .river]
        if let idx = order.firstIndex(of: street), idx > 0 {
            return order[idx - 1]
        }
        return .preflop
    }
    
    private func getChipGradient(_ chipColor: String) -> LinearGradient {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChip
        case "red": return ChipColors.redChip
        case "blue": return ChipColors.blueChip
        case "green": return ChipColors.greenChip
        case "orange": return ChipColors.orangeChip
        case "black": return ChipColors.blackChip
        case "gold": return ChipColors.goldChip
        default: return ChipColors.goldChip
        }
    }
    
    private func getChipBorderColor(_ chipColor: String) -> Color {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChipBorder
        case "red": return ChipColors.redChipBorder
        case "blue": return ChipColors.blueChipBorder
        case "green": return ChipColors.greenChipBorder
        case "orange": return ChipColors.orangeChipBorder
        case "black": return ChipColors.blackChipBorder
        case "gold": return ChipColors.goldChipBorder
        default: return ChipColors.goldChipBorder
        }
    }
    
    private func getChipTextColor(_ chipColor: String) -> Color {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChipText
        case "red": return ChipColors.redChipText
        case "blue": return ChipColors.blueChipText
        case "green": return ChipColors.greenChipText
        case "orange": return ChipColors.orangeChipText
        case "black": return ChipColors.blackChipText
        case "gold": return ChipColors.goldChipText
        default: return ChipColors.goldChipText
        }
    }
}

// MARK: - Component Views

struct HoleCardView: View {
    let isSmallScreen: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .overlay(
                    Rectangle()
                        .stroke(AppColors.gold.opacity(0.4), lineWidth: 2)
                )
            
            Text("CARD")
                .font(.system(size: isSmallScreen ? 12 : 16, weight: .bold))
                .foregroundColor(.white)
        }
        .aspectRatio(0.7, contentMode: .fit)
    }
}

struct CardSlotView: View {
    let isDealt: Bool
    let isSmallScreen: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isDealt ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    Rectangle()
                        .stroke(AppColors.gold.opacity(0.2), lineWidth: 2)
                )
            
            if isDealt {
                Text("CARD")
                    .font(.system(size: isSmallScreen ? 14 : 18, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("?")
                    .font(.system(size: isSmallScreen ? 20 : 26))
                    .foregroundColor(.white)
            }
        }
        .aspectRatio(0.7, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PlayerCardView: View {
    let player: PokerPlayer
    let isActive: Bool
    let isDealer: Bool
    let isSB: Bool
    let isBB: Bool
    let isSmallScreen: Bool
    
    var body: some View {
        HStack(spacing: isSmallScreen ? 8 : 12) {
            // Position badge
            if isDealer {
                Text("D")
                    .font(.system(size: isSmallScreen ? 9 : 11))
                    .padding(isSmallScreen ? 3 : 5)
                    .background(Color.blue)
                    .cornerRadius(3)
            } else if isSB {
                Text("SB")
                    .font(.system(size: isSmallScreen ? 9 : 11))
                    .padding(isSmallScreen ? 3 : 5)
                    .background(Color.gray)
                    .cornerRadius(3)
            } else if isBB {
                Text("BB")
                    .font(.system(size: isSmallScreen ? 9 : 11))
                    .padding(isSmallScreen ? 3 : 5)
                    .background(Color.orange)
                    .cornerRadius(3)
            }
            
            // Player name
            Text(player.name)
                .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                .foregroundColor(AppColors.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Bankroll
            Text("$\(player.bankroll)")
                .font(.system(size: isSmallScreen ? 16 : 20, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            // Status/Bet
            if player.folded {
                Text("FOLD")
                    .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                    .foregroundColor(.red)
            } else if player.isAllIn {
                Text("ALL-IN $\(player.bet)")
                    .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                    .foregroundColor(.orange)
            } else if player.bet > 0 {
                Text("$\(player.bet)")
                    .font(.system(size: isSmallScreen ? 16 : 22, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(isSmallScreen ? 8 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isActive ? AppColors.gold.opacity(0.2) : Color.clear)
    }
}

struct BettingControlsView: View {
    @ObservedObject var game: PokerGame
    let geometry: GeometryProxy
    let isSmallScreen: Bool
    
    var body: some View {
        Group {
            if game.activePlayerIndex < game.players.count {
                bettingControlsContent
            } else {
                Text("Invalid game state")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    private var bettingControlsContent: some View {
        VStack(spacing: isSmallScreen ? 4 : 6) {
            let player = game.players[game.activePlayerIndex]
            let toCall = max(0, game.currentBet - player.bet)
            
            // Header section - minimal height
            VStack(spacing: 2) {
                Text("\(player.name)'s Turn")
                    .font(.system(size: isSmallScreen ? 14 : 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if toCall > 0 {
                    Text("$\(toCall) to call")
                        .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                        .foregroundColor(AppColors.gold)
                } else {
                    Text("Check available")
                        .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            .frame(height: isSmallScreen ? 40 : 50)
            
            // Primary Actions - much larger, take up most space
            HStack(spacing: isSmallScreen ? 8 : 12) {
                Button("FOLD") {
                    game.fold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .font(.system(size: isSmallScreen ? 32 : 48, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                
                if toCall > 0 {
                    Button("CALL $\(min(toCall, player.bankroll))") {
                        game.call()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .font(.system(size: isSmallScreen ? 32 : 48, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                } else {
                    Button("CHECK") {
                        game.check()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.system(size: isSmallScreen ? 32 : 48, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
                
                if player.bankroll > 0 {
                    Button("ALL-IN") {
                        game.allIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: isSmallScreen ? 32 : 48, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Raise Options - fill remaining space with proper sizing
            if player.bankroll > toCall {
                let raises = game.getValidRaises()
                if !raises.isEmpty {
                    HStack(spacing: isSmallScreen ? 20 : 30) {
                        ForEach(Array(raises.prefix(6).enumerated()), id: \.offset) { index, raise in
                            Button(action: {
                                game.raise(to: raise.amount)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(getChipGradient(raise.chipColor))
                                        .overlay(
                                            Circle()
                                                .stroke(getChipBorderColor(raise.chipColor), lineWidth: isSmallScreen ? 8 : 10)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                                .padding(isSmallScreen ? 24 : 32)
                                        )
                                        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                                    
                                    VStack(spacing: isSmallScreen ? 4 : 6) {
                                        Text(raise.label)
                                            .font(.system(size: isSmallScreen ? 36 : 52, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                        Text("$\(raise.amount)")
                                            .font(.system(size: isSmallScreen ? 40 : 56, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                    }
                                    .foregroundColor(getChipTextColor(raise.chipColor))
                                }
                            }
                            .frame(minWidth: isSmallScreen ? 120 : 160, minHeight: isSmallScreen ? 120 : 160)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(isSmallScreen ? 10 : 14)
    }
    
    private func getChipGradient(_ chipColor: String) -> LinearGradient {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChip
        case "red": return ChipColors.redChip
        case "blue": return ChipColors.blueChip
        case "green": return ChipColors.greenChip
        case "orange": return ChipColors.orangeChip
        case "black": return ChipColors.blackChip
        case "gold": return ChipColors.goldChip
        default: return ChipColors.goldChip
        }
    }
    
    private func getChipBorderColor(_ chipColor: String) -> Color {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChipBorder
        case "red": return ChipColors.redChipBorder
        case "blue": return ChipColors.blueChipBorder
        case "green": return ChipColors.greenChipBorder
        case "orange": return ChipColors.orangeChipBorder
        case "black": return ChipColors.blackChipBorder
        case "gold": return ChipColors.goldChipBorder
        default: return ChipColors.goldChipBorder
        }
    }
    
    private func getChipTextColor(_ chipColor: String) -> Color {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChipText
        case "red": return ChipColors.redChipText
        case "blue": return ChipColors.blueChipText
        case "green": return ChipColors.greenChipText
        case "orange": return ChipColors.orangeChipText
        case "black": return ChipColors.blackChipText
        case "gold": return ChipColors.goldChipText
        default: return ChipColors.goldChipText
        }
    }
}

#Preview {
    PokerGameView(game: PokerGame())
}

