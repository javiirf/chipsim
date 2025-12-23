//
//  BlackjackGame.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation
import Combine

enum BlackjackMode: String, Codable {
    case single
    case twoHands
    case multiplayer
}

enum BlackjackPhase: String, Codable {
    case setup
    case betting
    case playing
    case dealer
    case result
}

struct BlackjackParticipant: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bankroll: Int
    var bet: Int = 0
    var lastBet: Int = 0
    var status: String = ""
    var autoRebet: Bool = false
    var isDoubleDown: Bool = false
    var hasInsurance: Bool = false
    var stats: PlayerStats = PlayerStats()
}

class BlackjackGame: ObservableObject {
    @Published var mode: BlackjackMode = .single
    @Published var phase: BlackjackPhase = .setup
    @Published var gameStarted: Bool = false
    @Published var roundNumber: Int = 0
    @Published var betConfirmed: Bool = false
    @Published var isDealing: Bool = false
    
    // Single player mode
    @Published var bankroll: Int = 0
    @Published var bet: Int = 0
    @Published var lastBet: Int = 0
    @Published var lastHand2Bet: Int = 0
    @Published var autoRebet: Bool = false
    @Published var status: String = ""
    @Published var isDoubleDown: Bool = false
    @Published var hasSurrendered: Bool = false
    @Published var hasInsurance: Bool = false
    @Published var insuranceBet: Int = 0
    
    // Two hands mode
    @Published var twoHandsMode: Bool = false
    @Published var hand2Bet: Int = 0
    @Published var hand2Status: String = ""
    @Published var hand2IsDoubleDown: Bool = false
    @Published var hand2HasSurrendered: Bool = false
    @Published var activeBox: Int = 1 // 1 or 2
    @Published var hand1Complete: Bool = false
    @Published var hand2Complete: Bool = false
    @Published var hand1WinAmount: Int = 0
    @Published var hand2WinAmount: Int = 0
    
    // Split hands
    @Published var isSplit: Bool = false
    @Published var splitCount: Int = 0 // 0 = no split, 1 = 2 hands, 2 = 3 hands, 3 = 4 hands
    @Published var splitBet: Int = 0
    @Published var splitBet2: Int = 0
    @Published var splitBet3: Int = 0
    @Published var activeHand: Int = 1 // 1-4
    @Published var hand1Result: String = ""
    @Published var hand2Result: String = ""
    @Published var hand3Result: String = ""
    @Published var hand4Result: String = ""
    @Published var splitOriginalBet: Int = 0
    @Published var split1DD: Bool = false
    @Published var split2DD: Bool = false
    @Published var split3DD: Bool = false
    @Published var split4DD: Bool = false
    
    // Hand 2 split (for two hands mode)
    @Published var hand2IsSplit: Bool = false
    @Published var hand2SplitCount: Int = 0
    @Published var hand2SplitBet: Int = 0
    @Published var hand2SplitBet2: Int = 0
    @Published var hand2SplitBet3: Int = 0
    @Published var hand2ActiveHand: Int = 1
    @Published var hand2Hand1Result: String = ""
    @Published var hand2Hand2Result: String = ""
    @Published var hand2Hand3Result: String = ""
    @Published var hand2Hand4Result: String = ""
    @Published var hand2SplitOriginalBet: Int = 0
    @Published var hand2Split1DD: Bool = false
    @Published var hand2Split2DD: Bool = false
    @Published var hand2Split3DD: Bool = false
    @Published var hand2Split4DD: Bool = false
    
    // Multiplayer
    @Published var participants: [BlackjackParticipant] = []
    @Published var activeParticipantIndex: Int = 0
    
    // Statistics
    @Published var stats: BlackjackStatistics = BlackjackStatistics()
    @Published var currentStreak: Int = 0
    @Published var streakType: String = "" // "win" or "lose"
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // Bet history for undo
    private var betHistory: [Int] = []
    
    // MARK: - Game Setup
    
    func startGame(mode: BlackjackMode, startingBankroll: Int, playerNames: [String] = []) {
        self.mode = mode
        self.gameStarted = true
        self.phase = .betting
        self.roundNumber = 1
        twoHandsMode = mode == .twoHands
        
        if mode == .multiplayer {
            let names = playerNames.isEmpty ? ["Player 1", "Player 2"] : playerNames
            participants = names.map { name in
                BlackjackParticipant(name: name, bankroll: startingBankroll)
            }
            bankroll = 0
        } else {
            participants = []
            bankroll = startingBankroll
        }
        
        resetRound()
    }
    
    func resetRound() {
        if mode == .multiplayer {
            betConfirmed = false
            isDealing = false
            phase = .betting
            for i in participants.indices {
                participants[i].status = ""
                participants[i].isDoubleDown = false
                participants[i].hasInsurance = false
                if participants[i].autoRebet && participants[i].lastBet > 0 {
                    participants[i].bet = participants[i].lastBet
                } else {
                    participants[i].bet = 0
                }
            }
            return
        }
        
        phase = .betting
        betConfirmed = false
        isDealing = false
        
        bet = 0
        hand2Bet = 0
        status = ""
        hand2Status = ""
        isDoubleDown = false
        hand2IsDoubleDown = false
        hasSurrendered = false
        hand2HasSurrendered = false
        hasInsurance = false
        insuranceBet = 0
        isSplit = false
        hand2IsSplit = false
        splitCount = 0
        hand2SplitCount = 0
        activeHand = 1
        hand2ActiveHand = 1
        activeBox = 1
        hand1Complete = false
        hand2Complete = false
        betConfirmed = false
        isDealing = false
        
        // Reset split hands
        splitBet = 0
        splitBet2 = 0
        splitBet3 = 0
        hand2SplitBet = 0
        hand2SplitBet2 = 0
        hand2SplitBet3 = 0
        hand1Result = ""
        hand2Result = ""
        hand3Result = ""
        hand4Result = ""
        hand2Hand1Result = ""
        hand2Hand2Result = ""
        hand2Hand3Result = ""
        hand2Hand4Result = ""
        hand1WinAmount = 0
        hand2WinAmount = 0
        
        if autoRebet && lastBet > 0 {
            bet = lastBet
            if twoHandsMode {
                hand2Bet = lastHand2Bet
            }
        }
    }
    
    // MARK: - Betting
    
    func placeBet(amount: Int, playerIndex: Int? = nil) {
        guard phase == .betting, amount > 0 else { return }
        
        if mode == .multiplayer {
            guard let idx = playerIndex, participants.indices.contains(idx) else { return }
            let available = participants[idx].bankroll + participants[idx].bet
            guard available > 0 else { return }
            AudioService.shared.playSound(.chip)
            let newBet = min(participants[idx].bet + amount, available)
            participants[idx].bet = newBet
            return
        }
        
        guard amount <= bankroll else { return }
        
        AudioService.shared.playSound(.chip)
        
        if mode == .twoHands {
            if activeBox == 1 {
                bet = min(bankroll, bet + amount)
            } else {
                hand2Bet = min(bankroll, hand2Bet + amount)
            }
        } else {
            bet = min(bankroll, bet + amount)
        }
        
        betHistory.append(amount)
    }
    
    func confirmBet() {
        guard phase == .betting, mode != .multiplayer else { return }
        
        if mode == .twoHands {
            guard bet > 0 && hand2Bet > 0 else { return }
            bankroll -= (bet + hand2Bet)
        } else {
            guard bet > 0 else { return }
            bankroll -= bet
        }
        
        lastBet = bet
        lastHand2Bet = hand2Bet
        betConfirmed = true
        phase = .playing
        
        AudioService.shared.playSound(.placeYourBets)
    }
    
    func confirmMultiplayerBets() {
        guard mode == .multiplayer else { return }
        
        AudioService.shared.playSound(.placeYourBets)
        for i in participants.indices where participants[i].bet > 0 {
            let wager = participants[i].bet
            guard participants[i].bankroll >= wager else { continue }
            participants[i].bankroll -= wager
            participants[i].lastBet = wager
            participants[i].status = "Locked"
        }
        
        phase = .playing
    }
    
    func undoBet() {
        guard phase == .betting, !betHistory.isEmpty, mode != .multiplayer else { return }
        
        AudioService.shared.playSound(.push)
        let lastBet = betHistory.removeLast()
        
        if mode == .twoHands {
            if activeBox == 1 {
                bet = max(0, bet - lastBet)
            } else {
                hand2Bet = max(0, hand2Bet - lastBet)
            }
        } else {
            bet = max(0, bet - lastBet)
        }
    }
    
    // MARK: - Game Actions
    
    func hit() {
        guard phase == .playing else { return }
        AudioService.shared.playSound(.deal)
        // Card dealing logic would go here
        // For now, this is a placeholder
    }
    
    func stand() {
        guard phase == .playing else { return }
        AudioService.shared.playSound(.push)
        
        if mode == .twoHands {
            if activeBox == 1 {
                hand1Complete = true
                if !hand2Complete {
                    activeBox = 2
                } else {
                    phase = .dealer
                }
            } else {
                hand2Complete = true
                if !hand1Complete {
                    activeBox = 1
                } else {
                    phase = .dealer
                }
            }
        } else {
            phase = .dealer
        }
    }
    
    func doubleDown() {
        guard phase == .playing, mode != .multiplayer else { return }
        
        let currentBet = mode == .twoHands && activeBox == 2 ? hand2Bet : bet
        guard currentBet > 0, currentBet <= bankroll else { return }
        
        AudioService.shared.playSound(.chip)
        bankroll -= currentBet
        
        if mode == .twoHands {
            if activeBox == 1 {
                bet += currentBet
                isDoubleDown = true
            } else {
                hand2Bet += currentBet
                hand2IsDoubleDown = true
            }
        } else {
            bet += currentBet
            isDoubleDown = true
        }
        
        // After double down, automatically stand
        stand()
    }
    
    func split() {
        guard phase == .playing, mode != .multiplayer else { return }
        
        let currentBet = mode == .twoHands && activeBox == 2 ? hand2Bet : bet
        guard currentBet > 0, currentBet <= bankroll, splitCount < 3 else { return }
        
        AudioService.shared.playSound(.chip)
        bankroll -= currentBet
        
        if mode == .twoHands {
            if activeBox == 1 {
                isSplit = true
                splitCount += 1
                splitOriginalBet = bet
                if splitCount == 1 {
                    splitBet = bet
                } else if splitCount == 2 {
                    splitBet2 = bet
                } else {
                    splitBet3 = bet
                }
                activeHand = splitCount + 1
            } else {
                hand2IsSplit = true
                hand2SplitCount += 1
                hand2SplitOriginalBet = hand2Bet
                if hand2SplitCount == 1 {
                    hand2SplitBet = hand2Bet
                } else if hand2SplitCount == 2 {
                    hand2SplitBet2 = hand2Bet
                } else {
                    hand2SplitBet3 = hand2Bet
                }
                hand2ActiveHand = hand2SplitCount + 1
            }
        } else {
            isSplit = true
            splitCount += 1
            splitOriginalBet = bet
            if splitCount == 1 {
                splitBet = bet
            } else if splitCount == 2 {
                splitBet2 = bet
            } else {
                splitBet3 = bet
            }
            activeHand = splitCount + 1
        }
    }
    
    func surrender() {
        guard phase == .playing, mode != .multiplayer else { return }
        
        AudioService.shared.playSound(.lose)
        
        if mode == .twoHands {
            if activeBox == 1 {
                hasSurrendered = true
                bankroll += bet / 2
                hand1Complete = true
                if !hand2Complete {
                    activeBox = 2
                } else {
                    phase = .dealer
                }
            } else {
                hand2HasSurrendered = true
                bankroll += hand2Bet / 2
                hand2Complete = true
                if !hand1Complete {
                    activeBox = 1
                } else {
                    phase = .dealer
                }
            }
        } else {
            hasSurrendered = true
            bankroll += bet / 2
            phase = .dealer
        }
    }
    
    func takeInsurance() {
        guard phase == .playing, !hasInsurance, mode != .multiplayer else { return }
        
        let insuranceAmount = (mode == .twoHands && activeBox == 2 ? hand2Bet : bet) / 2
        guard insuranceAmount > 0, insuranceAmount <= bankroll else { return }
        
        AudioService.shared.playSound(.chip)
        bankroll -= insuranceAmount
        insuranceBet = insuranceAmount
        hasInsurance = true
    }
    
    // MARK: - Multiplayer Helpers
    
    func setParticipantBet(index: Int, amount: Int) {
        guard mode == .multiplayer, phase == .betting, participants.indices.contains(index), amount > 0 else { return }
        AudioService.shared.playSound(.chip)
        let available = participants[index].bankroll + participants[index].bet
        participants[index].bet = min(amount, available)
    }
    
    func resetParticipant(index: Int) {
        guard mode == .multiplayer, participants.indices.contains(index) else { return }
        participants[index].bet = 0
        participants[index].status = ""
        participants[index].isDoubleDown = false
        participants[index].hasInsurance = false
    }
    
    func resolveMultiplayerResult(for index: Int, outcome: String) {
        guard mode == .multiplayer, participants.indices.contains(index) else { return }
        
        var participant = participants[index]
        let wager = participant.bet > 0 ? participant.bet : participant.lastBet
        guard wager > 0 else { return }
        
        AudioService.shared.playSound(outcome.lowercased() == "win" || outcome.lowercased() == "blackjack" ? .win : .push)
        
        let payout = payoutAmount(for: outcome, betAmount: wager)
        let net = payout - wager
        
        participant.bankroll += payout
        participant.lastBet = wager
        participant.status = outcome.capitalized
        participant.stats.handsPlayed += 1
        
        switch outcome.lowercased() {
        case "win":
            participant.stats.wins += 1
        case "blackjack":
            participant.stats.wins += 1
            participant.stats.blackjacks += 1
        case "push":
            participant.stats.pushes += 1
        default:
            participant.stats.losses += 1
        }
        
        if net > 0 {
            participant.stats.totalWon += net
            participant.stats.biggestWin = max(participant.stats.biggestWin, net)
        } else if net < 0 {
            participant.stats.totalLost += abs(net)
        }
        
        participant.bet = participant.autoRebet ? participant.lastBet : 0
        participant.isDoubleDown = false
        participant.hasInsurance = false
        
        participants[index] = participant
        
        if participants.allSatisfy({ !$0.status.isEmpty }) {
            phase = .result
        }
        updateStats(outcome: outcome, net: net)
    }
    
    func nextMultiplayerRound() {
        guard mode == .multiplayer else { return }
        roundNumber += 1
        phase = .betting
        for i in participants.indices {
            participants[i].status = ""
            participants[i].isDoubleDown = false
            participants[i].hasInsurance = false
            if participants[i].autoRebet && participants[i].lastBet > 0 {
                participants[i].bet = participants[i].lastBet
            } else {
                participants[i].bet = 0
            }
        }
    }
    
    // MARK: - Round Completion
    
    func completeRound(outcome: String, betAmount: Int? = nil) {
        let currentBet: Int
        if mode == .twoHands && activeBox == 2 {
            currentBet = betAmount ?? hand2Bet
        } else {
            currentBet = betAmount ?? bet
        }
        
        let payout = payoutAmount(for: outcome, betAmount: currentBet)
        let net = payout - currentBet
        
        if mode == .twoHands {
            if activeBox == 1 {
                hand1Result = outcome
                hand1WinAmount = payout
                bankroll += payout
            } else {
                hand2Result = outcome
                hand2WinAmount = payout
                bankroll += payout
            }
            
            updateStats(outcome: outcome, net: net)
            
            let hand1Done = !hand1Result.isEmpty
            let hand2Done = !hand2Result.isEmpty
            
            if hand1Done && hand2Done {
                phase = .result
                roundNumber += 1
                save()
                
                if autoRebet {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        self.resetRound()
                    }
                }
            } else {
                activeBox = activeBox == 1 ? 2 : 1
            }
            
            return
        } else {
            status = outcome
            bankroll += payout
        }
        
        updateStats(outcome: outcome, net: net)
        roundNumber += 1
        phase = .result
        save()
        
        if autoRebet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.resetRound()
            }
        }
    }
    
    private func payoutAmount(for outcome: String, betAmount: Int) -> Int {
        switch outcome.lowercased() {
        case "win": return betAmount * 2
        case "blackjack": return Int(Double(betAmount) * 2.5)
        case "push": return betAmount
        case "surrender": return betAmount / 2
        default: return 0
        }
    }
    
    private func updateStats(outcome: String, net: Int) {
        stats.handsPlayed += 1
        
        switch outcome.lowercased() {
        case "win":
            stats.wins += 1
            updateStreak(type: "win")
        case "blackjack":
            stats.wins += 1
            stats.blackjacks += 1
            updateStreak(type: "win")
        case "push":
            stats.pushes += 1
            updateStreak(type: "push")
        default:
            stats.losses += 1
            updateStreak(type: "lose")
        }
        
        if net > 0 {
            stats.totalWon += net
            stats.biggestWin = max(stats.biggestWin, net)
        } else if net < 0 {
            stats.totalLost += abs(net)
        }
    }
    
    private func updateStreak(type: String) {
        if type == streakType || streakType.isEmpty {
            if type == "win" {
                currentStreak += 1
            } else if type == "lose" {
                currentStreak -= 1
            }
            streakType = type
        } else {
            // Streak broken
            currentStreak = type == "win" ? 1 : -1
            streakType = type
        }
        
        if abs(currentStreak) >= 3 && type != "push" {
            AudioService.shared.playSound(.win) // Streak celebration
        }
    }
    
    func resetGame() {
        AudioService.shared.playSound(.push)
        gameStarted = false
        phase = .setup
        roundNumber = 0
        bankroll = 0
        bet = 0
        lastBet = 0
        participants = []
        stats = BlackjackStatistics()
        resetRound()
    }
    
    // MARK: - Persistence
    
    func save() {
        StorageService.shared.saveBlackjackGame(self)
        FirebaseService.shared.saveBlackjackGame(self)
        
        StorageService.shared.saveBlackjackStats(stats)
        FirebaseService.shared.saveBlackjackStats(stats)
    }
}

