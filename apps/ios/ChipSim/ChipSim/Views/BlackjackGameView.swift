//
//  BlackjackGameView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

private let quickChipValues: [Int] = [5, 10, 25, 50, 100, 500]

struct BlackjackGameView: View {
    @ObservedObject var game: BlackjackGame
    @Environment(\.dismiss) var dismiss
    @State private var betAmount: String = ""
    @State private var participantInputs: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    header
                    
                    if game.mode == .multiplayer {
                        MultiplayerBlackjackView(
                            game: game,
                            betInputs: $participantInputs
                        )
                    } else {
                        SingleHandBlackjackView(
                            game: game,
                            betAmount: $betAmount
                        )
                    }
                    
                    statsSection
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
            .navigationTitle("Blackjack")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AudioService.shared.startBackgroundMusic()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Home") {
                        game.resetGame()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Round \(max(game.roundNumber, 1))")
                    .font(.system(size: FontSize.sm, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(game.mode == .multiplayer ? "Multiplayer" : (game.mode == .twoHands ? "Two Hands" : "Single"))
                    .font(.system(size: FontSize.xs, weight: .medium))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(AppColors.cardBackground)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                    )
            }
            
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Bankroll")
                        .font(.system(size: FontSize.xs))
                        .foregroundColor(.gray)
                    Text(game.mode == .multiplayer ? "$\(totalMultiplayerBankroll)" : "$\(game.bankroll)")
                        .font(.system(size: FontSize.lg, weight: .bold))
                        .foregroundColor(AppColors.gold)
                }
                
                if game.mode != .multiplayer {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Current Bet")
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(.gray)
                        Text("$\(currentBetDisplay)")
                            .font(.system(size: FontSize.md, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Toggle("Auto Rebet", isOn: $game.autoRebet)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.gold))
                        .font(.system(size: FontSize.sm, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var statsSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Stats")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                Spacer()
                Text(streakLabel)
                    .font(.system(size: FontSize.xs, weight: .semibold))
                    .foregroundColor(streakColor)
            }
            
            HStack(spacing: Spacing.sm) {
                StatisticsCardView(title: "Wins", value: game.stats.wins, color: .green)
                StatisticsCardView(title: "Losses", value: game.stats.losses, color: .red)
                StatisticsCardView(title: "Pushes", value: game.stats.pushes, color: .yellow)
                StatisticsCardView(title: "BJ", value: game.stats.blackjacks, color: AppColors.gold)
            }
        }
    }
    
    private var totalMultiplayerBankroll: Int {
        game.participants.reduce(0) { $0 + $1.bankroll }
    }
    
    private var currentBetDisplay: Int {
        if game.mode == .twoHands && game.activeBox == 2 {
            return game.hand2Bet
        }
        return game.bet
    }
    
    private var streakLabel: String {
        guard game.currentStreak != 0 else { return "Streak: Even" }
        let arrow = game.currentStreak > 0 ? "▲" : "▼"
        return "Streak: \(arrow) \(abs(game.currentStreak))"
    }
    
    private var streakColor: Color {
        if game.currentStreak > 0 { return .green }
        if game.currentStreak < 0 { return .red }
        return .gray
    }
}

// MARK: - Single / Two-Hand View

struct SingleHandBlackjackView: View {
    @ObservedObject var game: BlackjackGame
    @Binding var betAmount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if game.mode == .twoHands {
                handSelector
            }
            
            if game.phase == .betting {
                bettingPanel
            } else {
                statusPanel
            }
            
            actionPanel
            resultPanel
        }
    }
    
    private var handSelector: some View {
        HStack {
            Text("Active Hand")
                .font(.system(size: FontSize.sm, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Picker("Hand", selection: $game.activeBox) {
                Text("Hand 1").tag(1)
                Text("Hand 2").tag(2)
            }
            .pickerStyle(.segmented)
        }
        .padding(Spacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }
    
    private var bettingPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Place Your Bet")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(AppColors.gold)
            
            HStack(spacing: Spacing.sm) {
                TextField("Bet", text: $betAmount)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .font(.system(size: FontSize.sm))
                
                Button("Set") {
                    if let amount = Int(betAmount) {
                        game.placeBet(amount: amount)
                        betAmount = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.gold)
            }
            
            HStack(spacing: Spacing.sm) {
                ForEach(quickChipValues, id: \.self) { amount in
                    BettingChipView(amount: amount, isSelected: false) {
                        game.placeBet(amount: amount)
                    }
                }
            }
            
            HStack(spacing: Spacing.sm) {
                Button("Undo") {
                    game.undoBet()
                }
                .buttonStyle(.bordered)
                
                Button("Rebet Last") {
                    if game.mode == .twoHands {
                        if game.activeBox == 1 {
                            game.bet = game.lastBet
                        } else {
                            game.hand2Bet = game.lastHand2Bet
                        }
                    } else {
                        game.bet = game.lastBet
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Confirm & Deal") {
                    game.confirmBet()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(currentBet == 0)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Status")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(AppColors.gold)
            
            if game.mode == .twoHands {
                VStack(spacing: Spacing.sm) {
                    HandStatusView(status: game.hand1Result.isEmpty ? "In Play" : game.hand1Result, winAmount: game.hand1WinAmount)
                    HandStatusView(status: game.hand2Result.isEmpty ? "In Play" : game.hand2Result, winAmount: game.hand2WinAmount)
                }
            } else {
                HandStatusView(status: game.status.isEmpty ? "In Play" : game.status, winAmount: 0)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bet: $\(currentBet)")
                        .foregroundColor(.white)
                    Text("Bankroll: $\(game.bankroll)")
                        .foregroundColor(.gray)
                }
                Spacer()
                Button("Next Round") {
                    game.resetRound()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Actions")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(AppColors.gold)
            
            HStack(spacing: Spacing.sm) {
                Button("Hit") { game.hit() }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(game.phase != .playing)
                
                Button("Stand") { game.stand() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(game.phase != .playing)
                
                Button("Double") { game.doubleDown() }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(game.phase != .playing || currentBet == 0)
            }
            
            HStack(spacing: Spacing.sm) {
                Button("Split") { game.split() }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .disabled(game.phase != .playing)
                
                Button("Surrender") { game.surrender() }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(game.phase != .playing)
                
                Button("Insurance") { game.takeInsurance() }
                    .buttonStyle(.bordered)
                    .tint(.yellow)
                    .disabled(game.phase != .playing)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var resultPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Set Outcome")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(AppColors.gold)
            
            let betAmount = currentBet
            
            HStack(spacing: Spacing.sm) {
                Button("Win +$\(betAmount)") {
                    game.completeRound(outcome: "win", betAmount: betAmount)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(betAmount == 0)
                
                Button("Blackjack +$\(Int(Double(betAmount) * 1.5))") {
                    game.completeRound(outcome: "blackjack", betAmount: betAmount)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.gold)
                .disabled(betAmount == 0)
            }
            
            HStack(spacing: Spacing.sm) {
                Button("Push") {
                    game.completeRound(outcome: "push", betAmount: betAmount)
                }
                .buttonStyle(.bordered)
                .disabled(betAmount == 0)
                
                Button("Lose") {
                    game.completeRound(outcome: "lose", betAmount: betAmount)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(betAmount == 0)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var currentBet: Int {
        if game.mode == .twoHands && game.activeBox == 2 {
            return game.hand2Bet
        }
        return game.bet
    }
}

// MARK: - Multiplayer View

struct MultiplayerBlackjackView: View {
    @ObservedObject var game: BlackjackGame
    @Binding var betInputs: [UUID: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Players")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                Spacer()
                Button("Next Round") {
                    game.nextMultiplayerRound()
                }
                .buttonStyle(.bordered)
            }
            
            ForEach(Array(game.participants.enumerated()), id: \.element.id) { index, participant in
                participantCard(for: participant, index: index)
            }
            
            Button("Lock Bets & Deal") {
                game.confirmMultiplayerBets()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func participantCard(for participant: BlackjackParticipant, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.name)
                        .font(.system(size: FontSize.md, weight: .semibold))
                        .foregroundColor(AppColors.gold)
                    Text("Bankroll: $\(participant.bankroll)")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(.gray)
                }
                Spacer()
                Toggle(
                    "Auto Rebet",
                    isOn: Binding(
                        get: { game.participants.indices.contains(index) ? game.participants[index].autoRebet : false },
                        set: { newValue in
                            guard game.participants.indices.contains(index) else { return }
                            game.participants[index].autoRebet = newValue
                        }
                    )
                )
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.gold))
                    .labelsHidden()
            }
            
            HStack(spacing: Spacing.sm) {
                TextField("Bet", text: Binding(
                    get: { betInputs[participant.id] ?? "" },
                    set: { betInputs[participant.id] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .font(.system(size: FontSize.sm))
                
                Button("Set") {
                    if let amount = Int(betInputs[participant.id] ?? "") {
                        game.setParticipantBet(index: index, amount: amount)
                        betInputs[participant.id] = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.gold)
                
                Button("Clear") {
                    game.resetParticipant(index: index)
                }
                .buttonStyle(.bordered)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(quickChipValues, id: \.self) { amount in
                        BettingChipView(amount: amount, isSelected: false) {
                            game.placeBet(amount: amount, playerIndex: index)
                        }
                    }
                }
            }
            
            Text("Bet: $\(participant.bet)")
                .font(.system(size: FontSize.sm, weight: .medium))
                .foregroundColor(.white)
            
            HStack(spacing: Spacing.sm) {
                Button("Win") {
                    game.resolveMultiplayerResult(for: index, outcome: "win")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button("Blackjack") {
                    game.resolveMultiplayerResult(for: index, outcome: "blackjack")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.gold)
                
                Button("Push") {
                    game.resolveMultiplayerResult(for: index, outcome: "push")
                }
                .buttonStyle(.bordered)
                
                Button("Lose") {
                    game.resolveMultiplayerResult(for: index, outcome: "lose")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            if !participant.status.isEmpty {
                HandStatusView(status: participant.status, winAmount: 0)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    BlackjackGameView(game: BlackjackGame())
}
