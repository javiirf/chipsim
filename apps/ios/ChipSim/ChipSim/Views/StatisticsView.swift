//
//  StatisticsView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

struct StatisticsView: View {
    var pokerGame: PokerGame?
    var blackjackGame: BlackjackGame?
    @State private var selectedTab = "poker"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Stats", selection: $selectedTab) {
                    Text("Poker").tag("poker")
                    Text("Blackjack").tag("blackjack")
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    if selectedTab == "poker" {
                        PokerStatisticsView(game: pokerGame)
                    } else {
                        BlackjackStatisticsView(game: blackjackGame)
                    }
                }
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
            .navigationTitle("Statistics")
        }
    }
}

struct PokerStatisticsView: View {
    var game: PokerGame?
    
    var body: some View {
        VStack(spacing: 20) {
            if let game = game, !game.seriesStats.isEmpty {
                // Series Leaderboard
                VStack(alignment: .leading, spacing: 12) {
                    Text("Series Leaderboard")
                        .font(.headline)
                        .foregroundColor(AppColors.gold)
                    
                    ForEach(Array(game.seriesStats.sorted { (a, b) in
                        let aScore = a.value.seriesWins - a.value.seriesLosses
                        let bScore = b.value.seriesWins - b.value.seriesLosses
                        return aScore > bScore
                    }), id: \.key) { name, stats in
                        HStack {
                            Text(name)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(stats.seriesWins)W - \(stats.seriesLosses)L")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                Text("No series statistics yet")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }
}

struct BlackjackStatisticsView: View {
    var game: BlackjackGame?
    
    var body: some View {
        VStack(spacing: 20) {
            if let game = game {
                // Overall Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overall Statistics")
                        .font(.headline)
                        .foregroundColor(AppColors.gold)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatisticsCardView(title: "Wins", value: game.stats.wins, color: .green)
                        StatisticsCardView(title: "Losses", value: game.stats.losses, color: .red)
                        StatisticsCardView(title: "Pushes", value: game.stats.pushes, color: AppColors.gold)
                        StatisticsCardView(title: "Blackjacks", value: game.stats.blackjacks, color: AppColors.gold)
                        StatisticsCardView(title: "Total Won", value: game.stats.totalWon, color: .green)
                        StatisticsCardView(title: "Total Lost", value: game.stats.totalLost, color: .red)
                        StatisticsCardView(title: "Biggest Win", value: game.stats.biggestWin, color: .green)
                        StatisticsCardView(title: "Hands Played", value: game.stats.handsPlayed, color: .gray)
                    }
                }
                .padding()
                
                // Streak
                if game.currentStreak != 0 {
                    VStack(spacing: 8) {
                        Text("Current Streak")
                            .font(.headline)
                            .foregroundColor(AppColors.gold)
                        
                        Text("\(game.currentStreak > 0 ? "+" : "")\(game.currentStreak)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(game.currentStreak > 0 ? .green : .red)
                        
                        Text(game.streakType == "win" ? "Wins" : "Losses")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .cornerRadius(12)
                }
                
                // Leaderboard
                if !game.leaderboard.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                    Text("Leaderboard")
                        .font(.headline)
                        .foregroundColor(AppColors.gold)
                        
                        ForEach(Array(game.leaderboard.sorted { $0.score > $1.score }.prefix(10)), id: \.id) { entry in
                            HStack {
                                Text(entry.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("$\(entry.score)")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.gold)
                            }
                            .padding()
                            .background(AppColors.cardBackground)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else {
                Text("No statistics yet")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    StatisticsView(pokerGame: nil, blackjackGame: nil)
}

