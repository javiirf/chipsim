//
//  HomeView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var audioService = AudioService.shared
    @State private var selectedTab = "general"
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: Spacing.md) {
                    // Header - Full width at top
                    VStack(spacing: Spacing.sm) {
                        Text("CHIP SIMULATOR")
                            .font(.system(size: FontSize.title, weight: .bold, design: .default))
                            .foregroundColor(AppColors.gold)
                            .tracking(2)
                        
                        Text("Track your chips. Play with real cards.")
                            .font(.system(size: FontSize.sm))
                            .foregroundColor(.gray)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.15)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.gold, lineWidth: 2)
                    )
                    .shadow(color: AppColors.gold.opacity(0.2), radius: 10)
                    
                    // Game Selection Cards - Side by side
                    HStack(spacing: Spacing.md) {
                        NavigationLink(destination: PokerSetupView()) {
                            GameCard(
                                title: "Texas Hold'em",
                                description: "2-8 players • Blinds • All-in tracking",
                                features: ["Series stats", "Burn card prompts", "Pot odds"]
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        NavigationLink(destination: BlackjackSetupView()) {
                            GameCard(
                                title: "Blackjack",
                                description: "Classic 21 • Hit, Stand, Double, Split",
                                features: ["Highscores", "Streak tracking", "Sound effects"]
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Instructions and Legal Disclaimer - Side by side
                    HStack(spacing: Spacing.md) {
                        InstructionsView(selectedTab: $selectedTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Legal Disclaimer
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("For Entertainment Only")
                                .font(.system(size: FontSize.md, weight: .semibold))
                                .foregroundColor(AppColors.gold)
                            
                            ScrollView {
                                Text("This app simulates casino chip tracking and does not involve real money gambling. No actual currency is wagered, won, or lost. Success in this game does not indicate future success in real money gambling.")
                                    .font(.system(size: FontSize.xs))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.cardBackground)
                        .cornerRadius(10)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Footer - Smaller buttons at bottom
                    HStack(spacing: Spacing.md) {
                        Button(action: {
                            audioService.toggleSound()
                        }) {
                            Image(systemName: audioService.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: FontSize.md))
                                .foregroundColor(AppColors.gold)
                                .frame(width: 32, height: 32)
                        }
                        
                        NavigationLink(destination: StatisticsView(pokerGame: nil, blackjackGame: nil).navigationBarTitleDisplayMode(.inline)) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: FontSize.md))
                                .foregroundColor(AppColors.gold)
                                .frame(width: 32, height: 32)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .font(.system(size: FontSize.md))
                                .foregroundColor(AppColors.gold)
                                .frame(width: 32, height: 32)
                        }
                        
                        Spacer()
                        
                        Text("v2.1")
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .padding(Spacing.md)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.29, blue: 0.05),
                        Color(red: 0.02, green: 0.19, blue: 0.02),
                        Color(red: 0.04, green: 0.23, blue: 0.04)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
        }
    }
}

struct GameCard: View {
    let title: String
    let description: String
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.system(size: FontSize.xl, weight: .bold))
                .foregroundColor(AppColors.gold)
            
            Text(description)
                .font(.system(size: FontSize.md))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(features, id: \.self) { feature in
                    Text("• \(feature)")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.gold.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppColors.gold.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct InstructionsView: View {
    @Binding var selectedTab: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("How It Works")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                // Tab buttons
                HStack(spacing: 0) {
                    TabButton(title: "General", isSelected: selectedTab == "general") {
                        selectedTab = "general"
                    }
                    TabButton(title: "Poker", isSelected: selectedTab == "poker") {
                        selectedTab = "poker"
                    }
                    TabButton(title: "Blackjack", isSelected: selectedTab == "blackjack") {
                        selectedTab = "blackjack"
                    }
                }
                .background(AppColors.cardBackground)
                .cornerRadius(6)
                
                // Content
                Group {
                    if selectedTab == "general" {
                        GeneralInstructions()
                    } else if selectedTab == "poker" {
                        PokerInstructions()
                    } else {
                        BlackjackInstructions()
                    }
                }
                .padding(Spacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(6)
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: FontSize.sm))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? AppColors.gold : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .background(isSelected ? AppColors.gold.opacity(0.2) : Color.clear)
    }
}

struct GeneralInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("This is a chip tracker, not a card game.")
                .fontWeight(.semibold)
            
            Text("Use real cards IRL - this app just tracks the chips and enforces betting rules.")
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("• Deal physical cards yourself")
                Text("• Track bets and pots digitally")
                Text("• Works on any device")
                Text("• Stats sync across sessions")
            }
        }
        .font(.system(size: FontSize.xs))
        .foregroundColor(.gray)
    }
}

struct PokerInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Texas Hold'em Rules:")
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("• Dealer button moves each hand")
                Text("• Small & Big blinds posted automatically")
                Text("• Burn card prompts before flop/turn/river")
                Text("• Declare winner at showdown manually")
            }
        }
        .font(.system(size: FontSize.xs))
        .foregroundColor(.gray)
    }
}

struct BlackjackInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Blackjack Rules:")
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("• Get as close to 21 without going over")
                Text("• Hit = Take another card")
                Text("• Stand = Keep your hand")
                Text("• Double = Double bet, get one card")
                Text("• Split = Split pairs into two hands")
                Text("• Blackjack pays 3:2")
            }
        }
        .font(.system(size: FontSize.xs))
        .foregroundColor(.gray)
    }
}

#Preview {
    HomeView()
}

