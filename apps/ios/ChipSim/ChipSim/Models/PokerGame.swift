//
//  PokerGame.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import Foundation
import Combine

enum PokerPhase: String, Codable {
    case setup
    case betting
    case showdown
    case result
}

enum PokerStreet: String, Codable {
    case preflop
    case flop
    case turn
    case river
}

struct PokerLastAction: Codable {
    var player: String
    var action: String
    var amount: Int?
}

struct PokerLastResult: Codable {
    var message: String
    var winner: Int?
    var winnerType: String? // "fold", "game", "elimination", "tie"
}

struct PokerHistoryState: Codable {
    var players: [PokerPlayer]
    var pot: Int
    var phase: PokerPhase
    var activePlayerIndex: Int
    var street: PokerStreet
    var lastAggressor: Int
    var minRaise: Int
    var currentBet: Int
    var dealerIndex: Int
    var blindsPosted: Bool
    var lastResult: PokerLastResult?
}

class PokerGame: ObservableObject {
    @Published var players: [PokerPlayer] = []
    @Published var pot: Int = 0
    @Published var phase: PokerPhase = .setup
    @Published var round: Int = 0
    @Published var gameStarted: Bool = false
    @Published var activePlayerIndex: Int = 0
    @Published var smallBlind: Int = 5
    @Published var bigBlind: Int = 10
    @Published var dealerIndex: Int = 0
    @Published var street: PokerStreet = .preflop
    @Published var lastAggressor: Int = -1
    @Published var minRaise: Int = 0
    @Published var currentBet: Int = 0
    @Published var lastResult: PokerLastResult?
    @Published var blindsPosted: Bool = false
    @Published var lastAction: PokerLastAction?
    @Published var burnCardPending: Bool = false
    @Published var burnCardStreet: PokerStreet = .preflop
    @Published var seriesStats: [String: SeriesStats] = [:]
    
    private var history: [PokerHistoryState] = []
    private let maxHistory = 20
    
    var canUndo: Bool {
        return !history.isEmpty
    }
    private let defaultPlayerNames = ["Player 1", "Player 2", "Player 3", "Player 4", "Player 5", "Player 6", "Player 7", "Player 8"]
    
    // MARK: - Game Setup
    
    func startGame(numPlayers: Int, buyIn: Int, playerNames: [String], sb: Int?, bb: Int?) {
        AudioService.shared.playSound(.push)
        
        players = []
        for i in 0..<numPlayers {
            let name = i < playerNames.count && !playerNames[i].isEmpty ? playerNames[i] : defaultPlayerNames[i]
            let player = PokerPlayer(name: name, bankroll: buyIn)
            
            // Initialize series stats
            if seriesStats[name] == nil {
                seriesStats[name] = SeriesStats()
            }
            players.append(player)
        }
        
        smallBlind = sb ?? calculateSmallBlind(buyIn: buyIn)
        bigBlind = bb ?? calculateBigBlind(buyIn: buyIn)
        gameStarted = true
        phase = .betting
        round = 1
        dealerIndex = 0
        street = .preflop
        pot = 0
        history = []
        lastResult = nil
        minRaise = bigBlind
        currentBet = 0
        blindsPosted = false
        
        postBlinds()
    }
    
    private func calculateSmallBlind(buyIn: Int) -> Int {
        if buyIn <= 20 { return 1 }
        if buyIn <= 50 { return 1 }
        if buyIn <= 100 { return 1 }
        if buyIn <= 200 { return 2 }
        if buyIn <= 500 { return 5 }
        if buyIn <= 1000 { return 5 }
        if buyIn <= 2000 { return 10 }
        return 25
    }
    
    private func calculateBigBlind(buyIn: Int) -> Int {
        if buyIn <= 20 { return 1 }
        if buyIn <= 50 { return 2 }
        if buyIn <= 100 { return 2 }
        if buyIn <= 200 { return 5 }
        if buyIn <= 500 { return 10 }
        if buyIn <= 1000 { return 10 }
        if buyIn <= 2000 { return 20 }
        return 50
    }
    
    // MARK: - Blinds
    
    func postBlinds() {
        guard !blindsPosted, players.count >= 2 else { return }
        
        saveHistory()
        AudioService.shared.playSound(.push)
        
        let sbIndex: Int
        let bbIndex: Int
        
        if players.count == 2 {
            // Heads-up: Dealer posts SB
            sbIndex = dealerIndex
            bbIndex = getNextNonFoldedPlayer(from: sbIndex)
        } else {
            // Multi-way: SB is left of dealer, BB is left of SB
            sbIndex = getNextNonFoldedPlayer(from: dealerIndex)
            bbIndex = getNextNonFoldedPlayer(from: sbIndex)
        }
        
        // Post small blind
        let sbAmount = min(smallBlind, players[sbIndex].bankroll)
        players[sbIndex].bet = sbAmount
        players[sbIndex].bankroll -= sbAmount
        players[sbIndex].roundContribution += sbAmount
        if players[sbIndex].bankroll == 0 {
            players[sbIndex].isAllIn = true
        }
        
        // Post big blind
        let bbAmount = min(bigBlind, players[bbIndex].bankroll)
        players[bbIndex].bet = bbAmount
        players[bbIndex].bankroll -= bbAmount
        players[bbIndex].roundContribution += bbAmount
        if players[bbIndex].bankroll == 0 {
            players[bbIndex].isAllIn = true
        }
        
        currentBet = max(sbAmount, bbAmount)
        blindsPosted = true
        
        // Reset action tracking
        for i in players.indices {
            players[i].acted = false
        }
        lastAggressor = -1
        minRaise = bigBlind
        
        // Set first to act
        if players.count == 2 {
            activePlayerIndex = sbIndex
        } else {
            activePlayerIndex = getNextActivePlayer(from: bbIndex)
        }
        
        // Skip all-in players
        if players[activePlayerIndex].isAllIn {
            activePlayerIndex = getNextActivePlayer(from: activePlayerIndex)
        }
    }
    
    // MARK: - Betting Actions
    
    func fold() {
        guard phase == .betting, activePlayerIndex < players.count else { return }
        
        saveHistory()
        AudioService.shared.playSound(.lose)
        
        players[activePlayerIndex].folded = true
        players[activePlayerIndex].stats.handsLost += 1
        lastAction = PokerLastAction(player: players[activePlayerIndex].name, action: "fold")
        
        if countActivePlayers() == 1 {
            if let winnerIndex = players.firstIndex(where: { !$0.folded }) {
                awardPot(to: winnerIndex, reason: "fold")
            }
            return
        }
        
        advanceAction()
        save()
    }
    
    func check() {
        guard phase == .betting, activePlayerIndex < players.count else { return }
        
        let player = players[activePlayerIndex]
        let toCall = currentBet - player.bet
        
        guard toCall == 0 else { return } // Can only check if no bet to call
        
        saveHistory()
        AudioService.shared.playSound(.push)
        
        players[activePlayerIndex].acted = true
        lastAction = PokerLastAction(player: player.name, action: "check")
        advanceAction()
        save()
    }
    
    func call() {
        guard phase == .betting, activePlayerIndex < players.count else { return }
        
        let player = players[activePlayerIndex]
        let toCall = currentBet - player.bet
        
        guard toCall > 0 else {
            check() // Nothing to call, this is a check
            return
        }
        
        saveHistory()
        AudioService.shared.playSound(.push)
        
        let actualCall = min(toCall, player.bankroll)
        players[activePlayerIndex].bankroll -= actualCall
        players[activePlayerIndex].bet += actualCall
        players[activePlayerIndex].roundContribution += actualCall
        players[activePlayerIndex].acted = true
        
        if players[activePlayerIndex].bankroll == 0 {
            players[activePlayerIndex].isAllIn = true
        }
        
        lastAction = PokerLastAction(player: player.name, action: "call", amount: actualCall)
        advanceAction()
        save()
    }
    
    func raise(to totalBet: Int) {
        guard phase == .betting, activePlayerIndex < players.count else { return }
        
        let player = players[activePlayerIndex]
        let currentPlayerBet = player.bet
        let amountToAdd = totalBet - currentPlayerBet
        
        guard totalBet > 0,
              totalBet > currentBet,
              amountToAdd <= player.bankroll,
              amountToAdd > 0 else { return }
        
        // Check minimum raise (except for all-in)
        let raiseAmount = totalBet - currentBet
        if amountToAdd < player.bankroll && raiseAmount < minRaise {
            return
        }
        
        saveHistory()
        AudioService.shared.playSound(.push)
        
        players[activePlayerIndex].bankroll -= amountToAdd
        players[activePlayerIndex].bet = totalBet
        players[activePlayerIndex].roundContribution += amountToAdd
        players[activePlayerIndex].acted = true
        
        if players[activePlayerIndex].bankroll == 0 {
            players[activePlayerIndex].isAllIn = true
        }
        
        // Update betting state
        if totalBet > currentBet {
            // Reset other players' acted flags
            for i in players.indices where i != activePlayerIndex && !players[i].folded && !players[i].isAllIn {
                players[i].acted = false
            }
            lastAggressor = activePlayerIndex
            minRaise = max(minRaise, raiseAmount)
            currentBet = totalBet
        }
        
        lastAction = PokerLastAction(player: player.name, action: currentBet == 0 ? "bets" : "raises to", amount: totalBet)
        advanceAction()
        save()
    }
    
    func allIn() {
        guard phase == .betting, activePlayerIndex < players.count else { return }
        
        let player = players[activePlayerIndex]
        let totalBet = player.bet + player.bankroll
        
        saveHistory()
        AudioService.shared.playSound(.push)
        
        // If this is a raise, reset others' acted flags
        if totalBet > currentBet {
            for i in players.indices where i != activePlayerIndex && !players[i].folded && !players[i].isAllIn {
                players[i].acted = false
            }
            lastAggressor = activePlayerIndex
            let raiseAmount = totalBet - currentBet
            if raiseAmount >= minRaise {
                minRaise = raiseAmount
            }
            currentBet = totalBet
        }
        
        let allInAmount = player.bankroll
        players[activePlayerIndex].roundContribution += allInAmount
        players[activePlayerIndex].bet = totalBet
        players[activePlayerIndex].bankroll = 0
        players[activePlayerIndex].acted = true
        players[activePlayerIndex].isAllIn = true
        
        lastAction = PokerLastAction(player: player.name, action: "allin", amount: totalBet)
        advanceAction()
        save()
    }
    
    // MARK: - Game Flow
    
    private func advanceAction() {
        if isBettingRoundComplete() {
            if countActivePlayers() == 1 {
                if let winnerIndex = players.firstIndex(where: { !$0.folded }) {
                    awardPot(to: winnerIndex, reason: "fold")
                }
                return
            }
            
            if countPlayersWhoCanAct() <= 1 {
                runOutBoard()
                return
            }
            
            if street == .river {
                goToShowdown()
            } else {
                nextStreet()
            }
        } else {
            activePlayerIndex = getNextActivePlayer(from: activePlayerIndex)
        }
    }
    
    private func isBettingRoundComplete() -> Bool {
        let activePlayers = getActivePlayers()
        guard activePlayers.count > 1 else { return true }
        
        for player in activePlayers {
            if player.isAllIn { continue }
            if !player.acted { return false }
            if player.bet < currentBet && player.bankroll > 0 { return false }
        }
        
        return true
    }
    
    private func nextStreet() {
        saveHistory()
        AudioService.shared.playSound(.push)
        
        // Move bets to pot
        var totalBets = 0
        for i in players.indices {
            totalBets += players[i].bet
            players[i].bet = 0
            players[i].acted = false
        }
        pot += totalBets
        currentBet = 0
        minRaise = bigBlind
        lastAggressor = -1
        
        // Advance street
        let streets: [PokerStreet] = [.preflop, .flop, .turn, .river]
        if let currentIndex = streets.firstIndex(of: street), currentIndex < streets.count - 1 {
            street = streets[currentIndex + 1]
        }
        
        // Post-flop action starts left of dealer
        activePlayerIndex = getNextActivePlayer(from: dealerIndex)
        
        // Trigger burn card animation
        burnCardPending = true
        burnCardStreet = street
    }
    
    func acknowledgeBurnCard() {
        AudioService.shared.playSound(.deal)
        burnCardPending = false
        
        if countPlayersWhoCanAct() <= 1 && phase == .betting {
            if street == .river {
                goToShowdown()
            } else {
                runOutBoard()
            }
        }
    }
    
    private func runOutBoard() {
        // Move all bets to pot
        var totalBets = 0
        for i in players.indices {
            totalBets += players[i].bet
            players[i].bet = 0
            players[i].acted = false
        }
        pot += totalBets
        currentBet = 0
        minRaise = bigBlind
        
        // Determine next street
        let streets: [PokerStreet] = [.preflop, .flop, .turn, .river]
        if let currentIndex = streets.firstIndex(of: street), currentIndex < streets.count - 1 {
            street = streets[currentIndex + 1]
            burnCardPending = true
            burnCardStreet = street
        } else {
            goToShowdown()
        }
    }
    
    private func goToShowdown() {
        // Move any remaining bets to pot
        var totalBets = 0
        for i in players.indices {
            totalBets += players[i].bet
            players[i].bet = 0
        }
        pot += totalBets
        
        phase = .showdown
    }
    
    func declareWinner(_ winnerIndex: Int?) {
        guard phase == .showdown else { return }
        
        saveHistory()
        
        if let winnerIndex = winnerIndex, winnerIndex < players.count {
            awardPot(to: winnerIndex, reason: "win")
        } else {
            // Tie - split pot
            let activePlayers = getActivePlayers()
            guard !activePlayers.isEmpty else { return }
            
            let totalPot = pot + players.reduce(0) { $0 + $1.bet }
            let share = totalPot / activePlayers.count
            let remainder = totalPot % activePlayers.count
            
            var remainderCount = remainder
            for i in players.indices where !players[i].folded {
                players[i].bankroll += share + (remainderCount > 0 ? 1 : 0)
                if remainderCount > 0 { remainderCount -= 1 }
                players[i].stats.handsTied += 1
                players[i].bet = 0
            }
            
            AudioService.shared.playSound(.push)
            let avgContribution = activePlayers.reduce(0) { $0 + $1.roundContribution } / activePlayers.count
            let profitPerPlayer = share - avgContribution
            lastResult = PokerLastResult(
                message: "Split Pot! \(profitPerPlayer >= 0 ? "+" : "")$\(profitPerPlayer) each",
                winner: nil,
                winnerType: "tie"
            )
            pot = 0
            phase = .result
        }
    }
    
    private func awardPot(to winnerIndex: Int, reason: String) {
        guard winnerIndex >= 0 && winnerIndex < players.count else { return }
        
        let totalPot = pot + players.reduce(0) { $0 + $1.bet }
        let winnerContribution = players[winnerIndex].roundContribution
        let profit = totalPot - winnerContribution
        
        players[winnerIndex].bankroll += totalPot
        players[winnerIndex].stats.handsWon += 1
        
        if reason == "fold" {
            AudioService.shared.playSound(.push)
        } else {
            AudioService.shared.playSound(.win)
        }
        
        // Mark non-winners as losses
        for i in players.indices {
            if i != winnerIndex && !players[i].folded {
                players[i].stats.handsLost += 1
            }
            players[i].bet = 0
        }
        
        pot = 0
        phase = .result
        
        let winnerName = players[winnerIndex].name
        if reason == "fold" {
            lastResult = PokerLastResult(message: "\(winnerName) wins +$\(profit)! (Others folded)", winner: winnerIndex, winnerType: "fold")
        } else {
            lastResult = PokerLastResult(message: "\(winnerName) wins +$\(profit)!", winner: winnerIndex, winnerType: "win")
        }
    }
    
    func newRound() {
        AudioService.shared.playSound(.push)
        
        // Remove players with no chips
        players = players.filter { $0.bankroll > 0 }
        
        if players.count <= 1 {
            if players.count == 1 {
                updateSeriesStats(winnerName: players[0].name)
                lastResult = PokerLastResult(message: "\(players[0].name) WINS THE GAME!", winner: 0, winnerType: "game")
            }
            phase = .result
            return
        }
        
        // Reset for new hand
        phase = .betting
        for i in players.indices {
            players[i].bet = 0
            players[i].roundContribution = 0
            players[i].acted = false
            players[i].folded = false
            players[i].isAllIn = false
        }
        round += 1
        street = .preflop
        pot = 0
        currentBet = 0
        blindsPosted = false
        lastAction = nil
        history = []
        
        // Move dealer button
        dealerIndex = (dealerIndex + 1) % players.count
        minRaise = bigBlind
        lastAggressor = -1
        
        postBlinds()
    }
    
    func resetGame() {
        AudioService.shared.playSound(.push)
        players = []
        pot = 0
        phase = .setup
        round = 0
        gameStarted = false
        activePlayerIndex = 0
        lastResult = nil
        history = []
        street = .preflop
        dealerIndex = 0
        currentBet = 0
        blindsPosted = false
        burnCardPending = false
    }
    
    func rematch() {
        AudioService.shared.playSound(.push)
        
        let playerNames = players.map { $0.name }
        let buyIn = players.first?.totalBuyIn ?? 100
        
        players = []
        for name in playerNames {
            players.append(PokerPlayer(name: name, bankroll: buyIn))
        }
        
        gameStarted = true
        phase = .betting
        round = 1
        dealerIndex = 0
        street = .preflop
        pot = 0
        history = []
        lastResult = nil
        minRaise = bigBlind
        currentBet = 0
        blindsPosted = false
        
        postBlinds()
        save()
    }
    
    // MARK: - Helper Functions
    
    private func getNextActivePlayer(from index: Int) -> Int {
        guard !players.isEmpty else { return 0 }
        var nextIndex = (index + 1) % players.count
        var attempts = 0
        while (players[nextIndex].folded || players[nextIndex].isAllIn) && attempts < players.count {
            nextIndex = (nextIndex + 1) % players.count
            attempts += 1
        }
        return nextIndex
    }
    
    private func getNextNonFoldedPlayer(from index: Int) -> Int {
        guard !players.isEmpty else { return 0 }
        var nextIndex = (index + 1) % players.count
        var attempts = 0
        while players[nextIndex].folded && attempts < players.count {
            nextIndex = (nextIndex + 1) % players.count
            attempts += 1
        }
        return nextIndex
    }
    
    func countActivePlayers() -> Int {
        return players.filter { !$0.folded }.count
    }
    
    func countPlayersWhoCanAct() -> Int {
        return players.filter { !$0.folded && !$0.isAllIn }.count
    }
    
    func getActivePlayers() -> [PokerPlayer] {
        return players.filter { !$0.folded }
    }
    
    func getTotalChipsInPlay() -> Int {
        return players.reduce(0) { $0 + $1.bankroll + $1.bet } + pot
    }
    
    func getChipLeader() -> PokerPlayer? {
        guard !players.isEmpty else { return nil }
        return players.max { ($0.bankroll + $0.bet) < ($1.bankroll + $1.bet) }
    }
    
    func getPotOdds() -> (ratio: Double, percentage: String, toCall: Int, pot: Int)? {
        guard activePlayerIndex < players.count else { return nil }
        let player = players[activePlayerIndex]
        let toCall = max(0, currentBet - player.bet)
        guard toCall > 0 else { return nil }
        
        let pot = self.pot + players.reduce(0) { $0 + $1.bet }
        let potAfterCall = pot + toCall
        let ratio = Double(potAfterCall) / Double(toCall)
        let percentage = String(format: "%.1f", (Double(toCall) / Double(potAfterCall)) * 100)
        
        return (ratio, percentage, toCall, pot)
    }
    
    func getValidRaises() -> [(label: String, amount: Int, chipColor: String)] {
        guard activePlayerIndex < players.count else { return [] }
        let player = players[activePlayerIndex]
        let currentPlayerBet = player.bet
        let toCall = currentBet - currentPlayerBet
        let minRaiseTotal = currentBet + minRaise
        let maxRaise = currentPlayerBet + player.bankroll
        
        guard maxRaise > currentBet else { return [] }
        
        var raises: [(label: String, amount: Int, chipColor: String)] = []
        var addedAmounts = Set<Int>()
        
        func addRaise(_ label: String, _ amount: Int, _ chipColor: String = "green") {
            let amt = amount
            if amt >= minRaiseTotal && amt <= maxRaise && !addedAmounts.contains(amt) && amt > 0 {
                addedAmounts.insert(amt)
                raises.append((label, amt, chipColor))
            }
        }
        
        let pot = self.pot + players.reduce(0) { $0 + $1.bet }
        
        // Min raise
        addRaise("Min", minRaiseTotal, "white")
        
        if currentBet > 0 {
            // Facing a bet - multipliers
            addRaise("2×", currentBet * 2, "red")
            addRaise("3×", currentBet * 3, "blue")
            addRaise("4×", currentBet * 4, "green")
            addRaise("5×", currentBet * 5, "orange")
            
            // Pot-sized raise
            let potRaise = currentBet + pot + toCall
            addRaise("Pot", potRaise, "gold")
        } else {
            // Opening bet
            if pot > 0 {
                addRaise("¼ Pot", pot / 4, "white")
                addRaise("⅓ Pot", pot / 3, "white")
                addRaise("½ Pot", pot / 2, "red")
                addRaise("⅔ Pot", pot * 2 / 3, "blue")
                addRaise("¾ Pot", pot * 3 / 4, "blue")
                addRaise("Pot", pot, "gold")
            }
            
            if street == .preflop {
                addRaise("$\(bigBlind * 2)", bigBlind * 2, "white")
                addRaise("$\(bigBlind * 3)", bigBlind * 3, "red")
                addRaise("$\(bigBlind * 4)", bigBlind * 4, "blue")
                addRaise("$\(bigBlind * 5)", bigBlind * 5, "green")
                addRaise("$\(bigBlind * 10)", bigBlind * 10, "black")
            }
        }
        
        return raises.sorted { $0.amount < $1.amount }
    }
    
    // MARK: - History & Undo
    
    private func saveHistory() {
        let state = PokerHistoryState(
            players: players,
            pot: pot,
            phase: phase,
            activePlayerIndex: activePlayerIndex,
            street: street,
            lastAggressor: lastAggressor,
            minRaise: minRaise,
            currentBet: currentBet,
            dealerIndex: dealerIndex,
            blindsPosted: blindsPosted,
            lastResult: lastResult
        )
        history.append(state)
        if history.count > maxHistory {
            history.removeFirst()
        }
    }
    
    func undo() {
        guard !history.isEmpty else { return }
        AudioService.shared.playSound(.push)
        
        let state = history.removeLast()
        players = state.players
        pot = state.pot
        phase = state.phase
        activePlayerIndex = state.activePlayerIndex
        street = state.street
        lastAggressor = state.lastAggressor
        minRaise = state.minRaise
        currentBet = state.currentBet
        dealerIndex = state.dealerIndex
        blindsPosted = state.blindsPosted
        lastResult = state.lastResult
    }
    
    // MARK: - Series Stats
    
    private func updateSeriesStats(winnerName: String) {
        if seriesStats[winnerName] == nil {
            seriesStats[winnerName] = SeriesStats()
        }
        seriesStats[winnerName]?.seriesWins += 1
        
        for player in players where player.name != winnerName {
            if seriesStats[player.name] == nil {
                seriesStats[player.name] = SeriesStats()
            }
            seriesStats[player.name]?.seriesLosses += 1
        }
    }
    
    func clearSeriesStats() {
        seriesStats = [:]
        StorageService.shared.savePokerSeriesStats(seriesStats)
        FirebaseService.shared.savePokerSeriesStats(seriesStats)
    }
    
    // MARK: - Persistence
    
    func save() {
        StorageService.shared.savePokerGame(self)
        FirebaseService.shared.savePokerGame(self)
        
        if !seriesStats.isEmpty {
            StorageService.shared.savePokerSeriesStats(seriesStats)
            FirebaseService.shared.savePokerSeriesStats(seriesStats)
        }
    }
}

