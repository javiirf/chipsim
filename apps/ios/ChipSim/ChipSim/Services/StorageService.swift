//
//  StorageService.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    // MARK: - Settings Storage
    
    func saveSoundEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "soundEnabled")
    }
    
    func loadSoundEnabled() -> Bool {
        return userDefaults.bool(forKey: "soundEnabled")
    }
    
    // MARK: - Poker Game State
    
    func savePokerGame(_ game: PokerGame) {
        savePokerGameData(game)
    }
    
    func loadPokerGame() -> PokerGame? {
        guard let data = loadPokerGameData() else { return nil }
        let game = PokerGame()
        game.players = data.players
        game.pot = data.pot
        game.phase = data.phase
        game.round = data.round
        game.gameStarted = data.gameStarted
        game.activePlayerIndex = data.activePlayerIndex
        game.smallBlind = data.smallBlind
        game.bigBlind = data.bigBlind
        game.dealerIndex = data.dealerIndex
        game.street = data.street
        game.lastAggressor = data.lastAggressor
        game.minRaise = data.minRaise
        game.currentBet = data.currentBet
        game.lastResult = data.lastResult
        game.blindsPosted = data.blindsPosted
        game.lastAction = data.lastAction
        game.burnCardPending = data.burnCardPending
        game.burnCardStreet = data.burnCardStreet
        game.seriesStats = data.seriesStats
        return game
    }
    
    // MARK: - Blackjack Game State
    
    func saveBlackjackGame(_ game: BlackjackGame) {
        saveBlackjackGameData(game)
    }
    
    func loadBlackjackGame() -> BlackjackGame? {
        guard let data = loadBlackjackGameData() else { return nil }
        let game = BlackjackGame()
        game.mode = data.mode
        game.phase = data.phase
        game.gameStarted = data.gameStarted
        game.roundNumber = data.roundNumber
        game.bankroll = data.bankroll
        game.bet = data.bet
        game.hand2Bet = data.hand2Bet
        game.lastBet = data.lastBet
        game.lastHand2Bet = data.lastHand2Bet
        game.autoRebet = data.autoRebet
        game.status = data.status
        game.participants = data.participants
        game.activeBox = data.activeBox
        game.stats = data.stats
        game.twoHandsMode = data.mode == .twoHands
        return game
    }
    
    // MARK: - Statistics
    
    func savePokerSeriesStats(_ stats: [String: SeriesStats]) {
        do {
            let data = try encoder.encode(stats)
            userDefaults.set(data, forKey: "pokerSeriesStats")
        } catch {
            print("Failed to save poker series stats: \(error)")
        }
    }
    
    func loadPokerSeriesStats() -> [String: SeriesStats] {
        guard let data = userDefaults.data(forKey: "pokerSeriesStats") else { return [:] }
        do {
            return try decoder.decode([String: SeriesStats].self, from: data)
        } catch {
            print("Failed to load poker series stats: \(error)")
            return [:]
        }
    }
    
    func saveBlackjackStats(_ stats: BlackjackStatistics) {
        do {
            let data = try encoder.encode(stats)
            userDefaults.set(data, forKey: "blackjackStats")
        } catch {
            print("Failed to save blackjack stats: \(error)")
        }
    }
    
    func loadBlackjackStats() -> BlackjackStatistics? {
        guard let data = userDefaults.data(forKey: "blackjackStats") else { return nil }
        do {
            return try decoder.decode(BlackjackStatistics.self, from: data)
        } catch {
            print("Failed to load blackjack stats: \(error)")
            return nil
        }
    }
    
    // MARK: - Leaderboard
    
    func saveLeaderboard(_ entries: [LeaderboardEntry]) {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: "leaderboard")
        } catch {
            print("Failed to save leaderboard: \(error)")
        }
    }
    
    func loadLeaderboard() -> [LeaderboardEntry] {
        guard let data = userDefaults.data(forKey: "leaderboard") else { return [] }
        do {
            return try decoder.decode([LeaderboardEntry].self, from: data)
        } catch {
            print("Failed to load leaderboard: \(error)")
            return []
        }
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        userDefaults.removeObject(forKey: "pokerGameState")
        userDefaults.removeObject(forKey: "blackjackGameState")
        userDefaults.removeObject(forKey: "pokerSeriesStats")
        userDefaults.removeObject(forKey: "blackjackStats")
        userDefaults.removeObject(forKey: "leaderboard")
    }
}

// MARK: - Codable Helpers

// Note: PokerGame and BlackjackGame use manual encoding/decoding
// due to ObservableObject requirements. We'll use a wrapper approach.
struct PokerGameData: Codable {
    var players: [PokerPlayer]
    var pot: Int
    var phase: PokerPhase
    var round: Int
    var gameStarted: Bool
    var activePlayerIndex: Int
    var smallBlind: Int
    var bigBlind: Int
    var dealerIndex: Int
    var street: PokerStreet
    var lastAggressor: Int
    var minRaise: Int
    var currentBet: Int
    var lastResult: PokerLastResult?
    var blindsPosted: Bool
    var lastAction: PokerLastAction?
    var burnCardPending: Bool
    var burnCardStreet: PokerStreet
    var seriesStats: [String: SeriesStats]
}

extension StorageService {
    func savePokerGameData(_ game: PokerGame) {
        let data = PokerGameData(
            players: game.players,
            pot: game.pot,
            phase: game.phase,
            round: game.round,
            gameStarted: game.gameStarted,
            activePlayerIndex: game.activePlayerIndex,
            smallBlind: game.smallBlind,
            bigBlind: game.bigBlind,
            dealerIndex: game.dealerIndex,
            street: game.street,
            lastAggressor: game.lastAggressor,
            minRaise: game.minRaise,
            currentBet: game.currentBet,
            lastResult: game.lastResult,
            blindsPosted: game.blindsPosted,
            lastAction: game.lastAction,
            burnCardPending: game.burnCardPending,
            burnCardStreet: game.burnCardStreet,
            seriesStats: game.seriesStats
        )
        
        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: "pokerGameState")
        } catch {
            print("Failed to save poker game: \(error)")
        }
    }
    
    func loadPokerGameData() -> PokerGameData? {
        guard let data = userDefaults.data(forKey: "pokerGameState") else { return nil }
        do {
            return try decoder.decode(PokerGameData.self, from: data)
        } catch {
            print("Failed to load poker game: \(error)")
            return nil
        }
    }
}

// BlackjackGame uses similar wrapper approach
struct BlackjackGameData: Codable {
    var mode: BlackjackMode
    var phase: BlackjackPhase
    var gameStarted: Bool
    var roundNumber: Int
    var bankroll: Int
    var bet: Int
    var hand2Bet: Int = 0
    var lastBet: Int
    var lastHand2Bet: Int = 0
    var autoRebet: Bool
    var status: String
    var participants: [BlackjackParticipant] = []
    var activeBox: Int = 1
    var stats: BlackjackStatistics
    // Add other essential properties
}

extension StorageService {
    func saveBlackjackGameData(_ game: BlackjackGame) {
        let data = BlackjackGameData(
            mode: game.mode,
            phase: game.phase,
            gameStarted: game.gameStarted,
            roundNumber: game.roundNumber,
            bankroll: game.bankroll,
            bet: game.bet,
            hand2Bet: game.hand2Bet,
            lastBet: game.lastBet,
            lastHand2Bet: game.lastHand2Bet,
            autoRebet: game.autoRebet,
            status: game.status,
            participants: game.participants,
            activeBox: game.activeBox,
            stats: game.stats
        )
        
        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: "blackjackGameState")
        } catch {
            print("Failed to save blackjack game: \(error)")
        }
    }
    
    func loadBlackjackGameData() -> BlackjackGameData? {
        guard let data = userDefaults.data(forKey: "blackjackGameState") else { return nil }
        do {
            return try decoder.decode(BlackjackGameData.self, from: data)
        } catch {
            print("Failed to load blackjack game: \(error)")
            return nil
        }
    }
}

