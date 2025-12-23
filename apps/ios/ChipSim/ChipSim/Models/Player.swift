//
//  Player.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation

// MARK: - Poker Player
struct PokerPlayer: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var bankroll: Int
    var totalBuyIn: Int
    var bet: Int
    var roundContribution: Int
    var acted: Bool
    var stats: PlayerStats
    var folded: Bool
    var isAllIn: Bool
    
    init(name: String, bankroll: Int) {
        self.id = UUID()
        self.name = name
        self.bankroll = bankroll
        self.totalBuyIn = bankroll
        self.bet = 0
        self.roundContribution = 0
        self.acted = false
        self.stats = PlayerStats()
        self.folded = false
        self.isAllIn = false
    }
}

// MARK: - Player Statistics
struct PlayerStats: Codable, Equatable {
    var handsWon: Int = 0
    var handsLost: Int = 0
    var handsTied: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var pushes: Int = 0
    var blackjacks: Int = 0
    var totalWon: Int = 0
    var totalLost: Int = 0
    var biggestWin: Int = 0
    var handsPlayed: Int = 0
}

// MARK: - Series Statistics (for Poker)
struct SeriesStats: Codable {
    var seriesWins: Int = 0
    var seriesLosses: Int = 0
    var handsWon: Int = 0
    var handsLost: Int = 0
}

