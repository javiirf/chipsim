//
//  FirebaseService.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation
import Combine

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
#endif

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var isConnected: Bool = false
    @Published var isReady: Bool = false
    
    #if canImport(FirebaseAuth)
    private var currentUser: User?
    #endif
    
    #if canImport(FirebaseDatabase)
    private var userDataRef: DatabaseReference?
    private var connectedRef: DatabaseReference?
    #endif
    
    private init() {
        // Firebase will be initialized in app startup
    }
    
    func initialize() {
        #if canImport(FirebaseCore)
        // Check if Firebase is already configured
        guard FirebaseApp.app() != nil else {
            print("Firebase not configured - ensure FirebaseApp.configure() is called")
            return
        }
        
        // Monitor connection status with error handling
        #if canImport(FirebaseDatabase)
        connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef?.observe(.value) { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.isConnected = snapshot.value as? Bool ?? false
                if !(self?.isConnected ?? false) {
                    print("Firebase Database disconnected")
                }
            }
        }
        #endif
        
        // Check auth state
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.currentUser = user
                #if canImport(FirebaseDatabase)
                self?.userDataRef = Database.database().reference(withPath: "users/\(user.uid)")
                #endif
                DispatchQueue.main.async {
                    self?.isReady = true
                }
            } else {
                // Sign in anonymously
                self?.signInAnonymously()
            }
        }
        #else
        print("Firebase SDK not available - app will work in offline mode only")
        isReady = false
        #endif
    }
    
    private func signInAnonymously(retryCount: Int = 0) {
        #if canImport(FirebaseAuth) && canImport(FirebaseDatabase)
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                let nsError = error as NSError
                print("Anonymous auth failed (attempt \(retryCount + 1)): \(error)")
                
                // Retry on network errors (max 3 attempts, with exponential backoff)
                if nsError.domain == "FIRAuthErrorDomain" && nsError.code == 17020 && retryCount < 3 {
                    let delay = Double(retryCount + 1) * 2.0 // 2s, 4s, 6s
                    print("Retrying anonymous auth in \(delay) seconds...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.signInAnonymously(retryCount: retryCount + 1)
                    }
                } else {
                    print("Anonymous auth failed permanently - app will work in offline mode")
                    DispatchQueue.main.async {
                        self?.isReady = false
                    }
                }
            } else if let user = result?.user {
                print("Anonymous auth successful: \(user.uid)")
                self?.currentUser = user
                self?.userDataRef = Database.database().reference(withPath: "users/\(user.uid)")
                DispatchQueue.main.async {
                    self?.isReady = true
                }
            }
        }
        #endif
    }
    
    func saveToCloud(key: String, data: [String: Any]) {
        #if canImport(FirebaseDatabase)
        guard isReady, let ref = userDataRef else { return }
        
        var dataWithTimestamp = data
        dataWithTimestamp["lastUpdated"] = ServerValue.timestamp()
        
        ref.child(key).setValue(dataWithTimestamp) { error, _ in
            if let error = error {
                print("Failed to save to cloud: \(error)")
            }
        }
        #endif
    }
    
    func loadFromCloud(key: String, completion: @escaping ([String: Any]?) -> Void) {
        #if canImport(FirebaseDatabase)
        guard isReady, let ref = userDataRef else {
            completion(nil)
            return
        }
        
        ref.child(key).observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.value as? [String: Any])
        }
        #else
        completion(nil)
        #endif
    }
    
    // MARK: - Poker Game Sync
    
    func savePokerGame(_ game: PokerGame) {
        // Save locally first
        StorageService.shared.savePokerGame(game)
        
        guard isReady else { return }
        
        // Save to cloud
        let gameData: [String: Any] = [
            "players": game.players.map { player in
                [
                    "name": player.name,
                    "bankroll": player.bankroll,
                    "totalBuyIn": player.totalBuyIn,
                    "bet": player.bet,
                    "roundContribution": player.roundContribution,
                    "acted": player.acted,
                    "folded": player.folded,
                    "isAllIn": player.isAllIn
                ]
            },
            "pot": game.pot,
            "phase": game.phase.rawValue,
            "round": game.round,
            "gameStarted": game.gameStarted,
            "activePlayerIndex": game.activePlayerIndex,
            "smallBlind": game.smallBlind,
            "bigBlind": game.bigBlind,
            "dealerIndex": game.dealerIndex,
            "street": game.street.rawValue,
            "currentBet": game.currentBet,
            "minRaise": game.minRaise,
            "blindsPosted": game.blindsPosted
        ]
        
        saveToCloud(key: "poker", data: gameData)
    }
    
    func loadPokerGame(completion: @escaping (PokerGame?) -> Void) {
        // Try cloud first
        loadFromCloud(key: "poker") { cloudData in
            if let cloudData = cloudData {
                // Decode from cloud data
                let game = PokerGame()
                // Decode properties from cloudData dictionary
                if let pot = cloudData["pot"] as? Int { game.pot = pot }
                if let phaseStr = cloudData["phase"] as? String { game.phase = PokerPhase(rawValue: phaseStr) ?? .setup }
                if let round = cloudData["round"] as? Int { game.round = round }
                // Add more decoding as needed
                completion(game)
                return
            }
            
            // Fallback to local
            completion(StorageService.shared.loadPokerGame())
        }
    }
    
    // MARK: - Blackjack Game Sync
    
    func saveBlackjackGame(_ game: BlackjackGame) {
        // Save locally first
        StorageService.shared.saveBlackjackGame(game)
        
        guard isReady else { return }
        
        // Save to cloud
        let gameData: [String: Any] = [
            "mode": game.mode.rawValue,
            "phase": game.phase.rawValue,
            "gameStarted": game.gameStarted,
            "roundNumber": game.roundNumber,
            "bankroll": game.bankroll,
            "bet": game.bet,
            "hand2Bet": game.hand2Bet,
            "lastBet": game.lastBet,
            "lastHand2Bet": game.lastHand2Bet,
            "status": game.status,
            "participants": game.participants.map { p in
                [
                    "name": p.name,
                    "bankroll": p.bankroll,
                    "bet": p.bet,
                    "lastBet": p.lastBet,
                    "status": p.status
                ]
            },
            "activeBox": game.activeBox
        ]
        
        saveToCloud(key: "blackjack", data: gameData)
    }
    
    func loadBlackjackGame(completion: @escaping (BlackjackGame?) -> Void) {
        loadFromCloud(key: "blackjack") { cloudData in
            if let cloudData = cloudData {
                let game = BlackjackGame()
                if let modeStr = cloudData["mode"] as? String { game.mode = BlackjackMode(rawValue: modeStr) ?? .single }
                if let phaseStr = cloudData["phase"] as? String { game.phase = BlackjackPhase(rawValue: phaseStr) ?? .setup }
                if let bankroll = cloudData["bankroll"] as? Int { game.bankroll = bankroll }
                if let bet = cloudData["bet"] as? Int { game.bet = bet }
                if let hand2Bet = cloudData["hand2Bet"] as? Int { game.hand2Bet = hand2Bet }
                if let lastBet = cloudData["lastBet"] as? Int { game.lastBet = lastBet }
                if let lastHand2Bet = cloudData["lastHand2Bet"] as? Int { game.lastHand2Bet = lastHand2Bet }
                if let activeBox = cloudData["activeBox"] as? Int { game.activeBox = activeBox }
                if let participants = cloudData["participants"] as? [[String: Any]] {
                    game.participants = participants.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let bankroll = dict["bankroll"] as? Int else { return nil }
                        var participant = BlackjackParticipant(name: name, bankroll: bankroll)
                        participant.bet = dict["bet"] as? Int ?? 0
                        participant.lastBet = dict["lastBet"] as? Int ?? 0
                        participant.status = dict["status"] as? String ?? ""
                        return participant
                    }
                }
                // Add more decoding as needed
                completion(game)
                return
            }
            
            completion(StorageService.shared.loadBlackjackGame())
        }
    }
    
    // MARK: - Statistics Sync
    
    func savePokerSeriesStats(_ stats: [String: SeriesStats]) {
        guard isReady else {
            StorageService.shared.savePokerSeriesStats(stats)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stats)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                saveToCloud(key: "pokerSeries", data: dict)
            }
        } catch {
            print("Failed to encode poker series stats: \(error)")
        }
        
        StorageService.shared.savePokerSeriesStats(stats)
    }
    
    func saveBlackjackStats(_ stats: BlackjackStatistics) {
        guard isReady else {
            StorageService.shared.saveBlackjackStats(stats)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stats)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                saveToCloud(key: "blackjackStats", data: dict)
            }
        } catch {
            print("Failed to encode blackjack stats: \(error)")
        }
        
        StorageService.shared.saveBlackjackStats(stats)
    }
    
    func deleteFromCloud(key: String) {
        #if canImport(FirebaseDatabase)
        guard isReady, let ref = userDataRef else { return }
        ref.child(key).removeValue()
        #endif
    }
    
    func getUserId() -> String? {
        #if canImport(FirebaseAuth)
        return currentUser?.uid
        #else
        return nil
        #endif
    }
}

