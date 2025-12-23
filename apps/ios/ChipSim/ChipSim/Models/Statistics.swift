//
//  Statistics.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation

// MARK: - Blackjack Statistics
struct BlackjackStatistics: Codable {
    var wins: Int = 0
    var losses: Int = 0
    var pushes: Int = 0
    var blackjacks: Int = 0
    var totalWon: Int = 0
    var totalLost: Int = 0
    var biggestWin: Int = 0
    var handsPlayed: Int = 0
    var currentStreak: Int = 0
    var streakType: String = "" // "win" or "lose"
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var score: Int
    var timestamp: TimeInterval
}

// MARK: - Poker Series Statistics
typealias PokerSeriesStats = [String: SeriesStats]

