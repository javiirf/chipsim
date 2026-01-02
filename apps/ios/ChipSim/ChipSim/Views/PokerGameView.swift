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
            let statusHeight: CGFloat = isSmallScreen ? 30 : 36
            let padding: CGFloat = isSmallScreen ? 8 : 12
            let resultBannerHeight: CGFloat = game.lastResult != nil ? (isSmallScreen ? 30 : 36) : 0
            let burnCardHeight: CGFloat = game.burnCardPending ? (isSmallScreen ? 60 : 70) : 0
            let spacing: CGFloat = isSmallScreen ? 2 : 4
            // Count spacing: after status, after result (if exists), after burn (if exists), after board, after player = 3-5 spacings
            let spacingCount: CGFloat = 3 + (game.lastResult != nil ? 1 : 0) + (game.burnCardPending ? 1 : 0)
            let totalExtraHeight = statusHeight + padding + resultBannerHeight + burnCardHeight + (spacing * spacingCount)
            // Calculate remaining height after status bar and optional elements, ensure geometry is valid
            let safeHeight = geometry.size.height.isFinite && geometry.size.height > 0 ? geometry.size.height : 400
            let remainingHeight = max(100, safeHeight - totalExtraHeight) // Minimum 100 to prevent issues
            // Board gets 35%, player card gets 10%, controls get 55%
            let boardHeight: CGFloat = max(50, remainingHeight * 0.35)
            let playerHeight: CGFloat = max(50, remainingHeight * 0.10)
            let controlsHeight: CGFloat = max(50, remainingHeight * 0.55)
            
            VStack(spacing: 0) {
                // Status Bar
                HStack(spacing: isSmallScreen ? 4 : 8) {
                    Text("Hand #\(game.round)")
                        .font(.system(size: isSmallScreen ? 10 : 12, weight: .medium))
                        .foregroundColor(.white)
                    Text("•")
                        .font(.system(size: isSmallScreen ? 10 : 12))
                        .foregroundColor(.white)
                    Text(game.street.rawValue.capitalized)
                        .font(.system(size: isSmallScreen ? 10 : 12, weight: .medium))
                        .foregroundColor(.white)
                    if game.phase == .betting, game.activePlayerIndex < game.players.count {
                        Text("•")
                            .font(.system(size: isSmallScreen ? 10 : 12))
                            .foregroundColor(.white)
                        Text("\(game.players[game.activePlayerIndex].name)'s Turn")
                            .font(.system(size: isSmallScreen ? 10 : 12, weight: .medium))
                            .foregroundColor(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer()
                    
                    if game.canUndo {
                        Button("UNDO") {
                            game.undo()
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: isSmallScreen ? 9 : 11))
                        .controlSize(.mini)
                    }
                    
                    Button("End") {
                        game.resetGame()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: isSmallScreen ? 9 : 11))
                    .controlSize(.mini)
                }
                .padding(isSmallScreen ? 4 : 6)
                .frame(height: statusHeight)
                
                // Result Banner
                if let result = game.lastResult {
                    Text(result.message)
                        .font(.system(size: isSmallScreen ? 12 : 14, weight: .semibold))
                        .foregroundColor(AppColors.gold)
                        .padding(isSmallScreen ? 6 : 8)
                        .frame(maxWidth: .infinity)
                }
                
                // Burn Card Prompt
                if game.burnCardPending {
                    VStack(spacing: isSmallScreen ? 4 : 6) {
                        Text("BURN & DEAL")
                            .font(.system(size: isSmallScreen ? 12 : 14, weight: .semibold))
                            .foregroundColor(AppColors.gold)
                        
                        Button("Done") {
                            game.acknowledgeBurnCard()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .controlSize(.small)
                        .font(.system(size: isSmallScreen ? 11 : 13))
                    }
                    .padding(isSmallScreen ? 6 : 8)
                }
                
                // Top Section: Board and Pot
                HStack(spacing: isSmallScreen ? 8 : 10) {
                    // Community Board
                    VStack(spacing: isSmallScreen ? 4 : 6) {
                        Text("BOARD")
                            .font(.system(size: isSmallScreen ? 16 : 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: isSmallScreen ? 4 : 6) {
                            ForEach(0..<5) { index in
                                CardSlotView(
                                    isDealt: getCardSlotDealt(index: index),
                                    isSmallScreen: isSmallScreen
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(isSmallScreen ? 8 : 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: boardHeight)
                    
                    // Pot Display
                    VStack(spacing: isSmallScreen ? 4 : 6) {
                        Text("POT")
                            .font(.system(size: isSmallScreen ? 10 : 12))
                            .foregroundColor(.gray)
                        Text("$\(game.pot + game.players.reduce(0) { $0 + $1.bet })")
                            .font(.system(size: isSmallScreen ? 20 : 24, weight: .bold))
                            .foregroundColor(AppColors.gold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(isSmallScreen ? 8 : 10)
                    .frame(width: geometry.size.width * (isSmallScreen ? 0.12 : 0.15))
                    .frame(height: boardHeight)
                }
                
                // Active Player Card
                if game.phase == .betting && game.activePlayerIndex < game.players.count {
                    let activePlayer = game.players[game.activePlayerIndex]
                    PlayerCardView(
                        player: activePlayer,
                        isActive: true,
                        isDealer: game.activePlayerIndex == game.dealerIndex,
                        isSB: game.activePlayerIndex == getSBIndex(),
                        isBB: game.activePlayerIndex == getBBIndex(),
                        isSmallScreen: isSmallScreen
                    )
                    .frame(height: playerHeight)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: isSmallScreen ? 4 : 6) {
                            ForEach(Array(game.players.enumerated()), id: \.element.id) { index, player in
                                PlayerCardView(
                                    player: player,
                                    isActive: index == game.activePlayerIndex && game.phase == .betting,
                                    isDealer: index == game.dealerIndex,
                                    isSB: index == getSBIndex(),
                                    isBB: index == getBBIndex(),
                                    isSmallScreen: isSmallScreen
                                )
                            }
                        }
                    }
                    .frame(height: playerHeight)
                }
                
                // Controls - fills remaining space
                if game.phase == .result {
                    Button("Deal Next Hand") {
                        game.newRound()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.gold)
                    .font(.system(size: isSmallScreen ? 11 : 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: isSmallScreen ? 32 : 40)
                } else if game.phase == .showdown {
                    ScrollView {
                        VStack(spacing: isSmallScreen ? 3 : 4) {
                            Text("SHOWDOWN")
                                .font(.system(size: isSmallScreen ? 10 : 12, weight: .semibold))
                                .foregroundColor(AppColors.gold)
                            
                            ForEach(Array(game.getActivePlayers().enumerated()), id: \.element.id) { index, player in
                                if let playerIndex = game.players.firstIndex(where: { $0.id == player.id }) {
                                    Button("\(player.name) Wins") {
                                        game.declareWinner(playerIndex)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppColors.gold)
                                    .controlSize(.small)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: isSmallScreen ? 28 : 32)
                                }
                            }
                            
                            Button("Split Pot") {
                                game.declareWinner(nil)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                            .frame(height: isSmallScreen ? 28 : 32)
                        }
                    }
                    .frame(height: controlsHeight)
                } else if !game.burnCardPending && game.phase == .betting {
                    BettingControlsView(game: game, geometry: geometry, isSmallScreen: isSmallScreen)
                        .frame(height: controlsHeight)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(AppColors.feltGreen)
        .onAppear {
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            AudioService.shared.startBackgroundMusic()
        }
        .onDisappear {
            AppDelegate.orientationLock = .all
        }
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
    
    private func getSBIndex() -> Int {
        guard game.players.count >= 2 else { return 0 }
        if game.players.count == 2 {
            return game.dealerIndex
        }
        return (game.dealerIndex + 1) % game.players.count
    }
    
    private func getBBIndex() -> Int {
        guard game.players.count >= 2 else { return 1 }
        if game.players.count == 2 {
            return (game.dealerIndex + 1) % game.players.count
        }
        return (game.dealerIndex + 2) % game.players.count
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
                .font(.system(size: isSmallScreen ? 44 : 64, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                
                if toCall > 0 {
                    Button("CALL $\(min(toCall, player.bankroll))") {
                        game.call()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .font(.system(size: isSmallScreen ? 44 : 64, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                } else {
                    Button("CHECK") {
                        game.check()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.system(size: isSmallScreen ? 44 : 64, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
                
                if player.bankroll > 0 {
                    Button("ALL-IN") {
                        game.allIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: isSmallScreen ? 44 : 64, weight: .bold))
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

