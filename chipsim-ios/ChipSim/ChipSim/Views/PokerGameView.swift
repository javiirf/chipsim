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
            let statusHeight: CGFloat = isSmallScreen ? 35 : 45
            let boardHeight: CGFloat = isSmallScreen ? geometry.size.height * 0.35 : geometry.size.height * 0.40
            let playerHeight: CGFloat = isSmallScreen ? geometry.size.height * 0.18 : geometry.size.height * 0.20
            let controlsHeight: CGFloat = geometry.size.height * 0.4
            
            VStack(spacing: isSmallScreen ? 2 : 4) {
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
                .background(AppColors.cardBackground)
                .cornerRadius(4)
                
                // Result Banner
                if let result = game.lastResult {
                    Text(result.message)
                        .font(.system(size: isSmallScreen ? 12 : 14, weight: .semibold))
                        .foregroundColor(AppColors.gold)
                        .padding(isSmallScreen ? 6 : 8)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.cardBackground)
                        .cornerRadius(4)
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
                    .background(AppColors.cardBackground)
                    .cornerRadius(4)
                }
                
                // Top Section: Board and Pot
                HStack(spacing: isSmallScreen ? 6 : 8) {
                    // Community Board
                    VStack(spacing: isSmallScreen ? 6 : 8) {
                        Text("BOARD")
                            .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: isSmallScreen ? 6 : 8) {
                            ForEach(0..<5) { index in
                                CardSlotView(
                                    isDealt: getCardSlotDealt(index: index),
                                    isSmallScreen: isSmallScreen
                                )
                            }
                        }
                    }
                    .padding(isSmallScreen ? 8 : 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: boardHeight)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                    
                    // Pot Display
                    VStack(spacing: isSmallScreen ? 6 : 8) {
                        Text("POT")
                            .font(.system(size: isSmallScreen ? 12 : 14))
                            .foregroundColor(.gray)
                        Text("$\(game.pot + game.players.reduce(0) { $0 + $1.bet })")
                            .font(.system(size: isSmallScreen ? 22 : 28, weight: .bold))
                            .foregroundColor(AppColors.gold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(isSmallScreen ? 8 : 12)
                    .frame(width: geometry.size.width * (isSmallScreen ? 0.24 : 0.28))
                    .frame(height: boardHeight)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
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
                
                Spacer(minLength: 0)
                
                // Controls - Fixed at 40% height
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
            .padding(isSmallScreen ? 2 : 4)
            .frame(width: geometry.size.width, height: geometry.size.height)
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
        .onAppear {
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
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
            RoundedRectangle(cornerRadius: isSmallScreen ? 6 : 8)
                .fill(isDealt ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                .frame(width: isSmallScreen ? 45 : 60, height: isSmallScreen ? 65 : 85)
                .overlay(
                    RoundedRectangle(cornerRadius: isSmallScreen ? 6 : 8)
                        .stroke(AppColors.gold.opacity(0.3), lineWidth: isSmallScreen ? 2 : 3)
                )
            
            if isDealt {
                Text("CARD")
                    .font(.system(size: isSmallScreen ? 11 : 14, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("?")
                    .font(.system(size: isSmallScreen ? 16 : 20))
                    .foregroundColor(.white)
            }
        }
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
        VStack(alignment: .leading, spacing: isSmallScreen ? 4 : 6) {
            HStack {
                Text(player.name)
                    .font(.system(size: isSmallScreen ? 12 : 16, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
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
            }
            
            Text("$\(player.bankroll)")
                .font(.system(size: isSmallScreen ? 20 : 24, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            if player.folded {
                Text("FOLD")
                    .font(.system(size: isSmallScreen ? 10 : 12))
                    .foregroundColor(.red)
            } else if player.isAllIn {
                Text("ALL-IN $\(player.bet)")
                    .font(.system(size: isSmallScreen ? 10 : 12))
                    .foregroundColor(.orange)
            } else if player.bet > 0 {
                Text("$\(player.bet)")
                    .font(.system(size: isSmallScreen ? 10 : 12))
                    .foregroundColor(.green)
            }
        }
        .padding(isSmallScreen ? 8 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(isActive ? AppColors.gold.opacity(0.3) : AppColors.cardBackground)
        .cornerRadius(isSmallScreen ? 4 : 6)
        .overlay(
            RoundedRectangle(cornerRadius: isSmallScreen ? 4 : 6)
                .stroke(isActive ? AppColors.gold : AppColors.gold.opacity(0.2), lineWidth: isActive ? 2 : 1)
        )
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
        VStack(spacing: isSmallScreen ? 2 : 4) {
            let player = game.players[game.activePlayerIndex]
            let toCall = max(0, game.currentBet - player.bet)
            
            Text("\(player.name)'s Turn")
                .font(.system(size: isSmallScreen ? 10 : 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if toCall > 0 {
                Text("$\(toCall) to call")
                    .font(.system(size: isSmallScreen ? 8 : 10))
                    .foregroundColor(AppColors.gold)
            } else {
                Text("Check available")
                    .font(.system(size: isSmallScreen ? 8 : 10))
                    .foregroundColor(.green)
            }
            
            // Primary Actions
            HStack(spacing: isSmallScreen ? 3 : 4) {
                Button("Fold") {
                    game.fold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .font(.system(size: isSmallScreen ? 10 : 12, weight: .bold))
                .frame(height: isSmallScreen ? 32 : 38)
                .frame(maxWidth: .infinity)
                
                if toCall > 0 {
                    Button("Call $\(min(toCall, player.bankroll))") {
                        game.call()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .font(.system(size: isSmallScreen ? 10 : 12, weight: .bold))
                    .frame(height: isSmallScreen ? 32 : 38)
                    .frame(maxWidth: .infinity)
                } else {
                    Button("CHECK") {
                        game.check()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.system(size: isSmallScreen ? 10 : 12, weight: .bold))
                    .frame(height: isSmallScreen ? 32 : 38)
                    .frame(maxWidth: .infinity)
                }
                
                if player.bankroll > 0 {
                    Button("ALL-IN") {
                        game.allIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: isSmallScreen ? 10 : 12, weight: .bold))
                    .frame(height: isSmallScreen ? 32 : 38)
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Raise Options - 6 chips across the bottom
            if player.bankroll > toCall {
                let raises = game.getValidRaises()
                if !raises.isEmpty {
                    VStack(alignment: .leading, spacing: isSmallScreen ? 2 : 4) {
                        Text("RAISE TO")
                            .font(.system(size: isSmallScreen ? 10 : 12))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: isSmallScreen ? 3 : 4) {
                            ForEach(Array(raises.prefix(6).enumerated()), id: \.offset) { index, raise in
                                Button(action: {
                                    game.raise(to: raise.amount)
                                }) {
                                    GeometryReader { chipGeometry in
                                        ZStack {
                                            Circle()
                                                .fill(getChipGradient(raise.chipColor))
                                                .overlay(
                                                    Circle()
                                                        .stroke(getChipBorderColor(raise.chipColor), lineWidth: isSmallScreen ? 1 : 1.5)
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                                        .frame(width: chipGeometry.size.width * 0.7, height: chipGeometry.size.height * 0.7)
                                                )
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                            
                                            VStack(spacing: isSmallScreen ? 1 : 2) {
                                                Text(raise.label)
                                                    .font(.system(size: isSmallScreen ? 10 : 12, weight: .bold))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                                Text("$\(raise.amount)")
                                                    .font(.system(size: isSmallScreen ? 11 : 14, weight: .bold))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                            }
                                            .foregroundColor(getChipTextColor(raise.chipColor))
                                        }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(isSmallScreen ? 4 : 6)
        .background(AppColors.cardBackground)
        .cornerRadius(isSmallScreen ? 4 : 6)
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

