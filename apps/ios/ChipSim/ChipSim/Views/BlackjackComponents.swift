//
//  BlackjackComponents.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

// MARK: - Card View
struct CardView: View {
    let value: String
    let suit: String
    let isFaceDown: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isFaceDown ? Color.blue : Color.white)
                .frame(width: 40, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
            
            if isFaceDown {
                Text("CARD")
                    .font(.system(size: FontSize.sm, weight: .bold))
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: FontSize.md, weight: .semibold))
                        .foregroundColor(suit == "♥" || suit == "♦" ? .red : .white)
                    Text(suit)
                        .font(.system(size: FontSize.md))
                        .foregroundColor(suit == "♥" || suit == "♦" ? .red : .white)
                }
            }
        }
    }
}

// MARK: - Hand Display
struct HandDisplayView: View {
    let cards: [Card]
    let total: Int
    let isDealer: Bool
    let showDealerCard: Bool
    
    struct Card {
        let value: String
        let suit: String
    }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: -16) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    CardView(
                        value: card.value,
                        suit: card.suit,
                        isFaceDown: isDealer && index == 0 && !showDealerCard
                    )
                }
            }
            
            if !isDealer || showDealerCard {
                Text("Total: \(total)")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(total > 21 ? AppColors.danger : AppColors.gold)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Betting Chip
struct BettingChipView: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Determine chip color based on amount
                let chipColor = getChipColorForAmount(amount)
                
                Circle()
                    .fill(chipColor.gradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(chipColor.borderColor, lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                
                VStack(spacing: 2) {
                    Text("$")
                        .font(.system(size: FontSize.xs))
                    Text("\(amount)")
                        .font(.system(size: FontSize.sm, weight: .bold))
                }
                .foregroundColor(chipColor.textColor)
            }
        }
    }
    
    private func getChipColorForAmount(_ amount: Int) -> (gradient: LinearGradient, borderColor: Color, textColor: Color) {
        switch amount {
        case 1: return (ChipColors.whiteChip, ChipColors.whiteChipBorder, ChipColors.whiteChipText)
        case 5: return (ChipColors.redChip, ChipColors.redChipBorder, ChipColors.redChipText)
        case 10: return (ChipColors.blueChip, ChipColors.blueChipBorder, ChipColors.blueChipText)
        case 25: return (ChipColors.greenChip, ChipColors.greenChipBorder, ChipColors.greenChipText)
        case 50: return (ChipColors.orangeChip, ChipColors.orangeChipBorder, ChipColors.orangeChipText)
        case 100: return (ChipColors.blackChip, ChipColors.blackChipBorder, ChipColors.blackChipText)
        default:
            if amount >= 500 {
                return (ChipColors.goldChip, ChipColors.goldChipBorder, ChipColors.goldChipText)
            } else if amount >= 100 {
                return (ChipColors.blackChip, ChipColors.blackChipBorder, ChipColors.blackChipText)
            } else {
                return (ChipColors.orangeChip, ChipColors.orangeChipBorder, ChipColors.orangeChipText)
            }
        }
    }
}

// MARK: - Hand Status Indicator
struct HandStatusView: View {
    let status: String
    let winAmount: Int
    
    var body: some View {
        HStack {
            Text(status)
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(statusColor)
            
            if winAmount != 0 {
                Text(winAmount > 0 ? "+$\(winAmount)" : "-$\(abs(winAmount))")
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(winAmount > 0 ? .green : .red)
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "win", "blackjack": return .green
        case "lose", "bust": return .red
        case "push": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Insurance Prompt
struct InsurancePromptView: View {
    let betAmount: Int
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Insurance Available")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(AppColors.gold)
            
            Text("Dealer shows an Ace. Would you like insurance?")
                .font(.system(size: FontSize.sm))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text("Insurance: $\(betAmount / 2)")
                .font(.system(size: FontSize.lg, weight: .bold))
                .foregroundColor(AppColors.gold)
            
            HStack(spacing: Spacing.sm) {
                Button("Yes") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)
                
                Button("No") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 1.5)
        )
    }
}

// MARK: - Split Hand Display
struct SplitHandDisplayView: View {
    let handNumber: Int
    let result: String
    let bet: Int
    let isDoubleDown: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Hand \(handNumber)")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                
                Spacer()
                
                if isDoubleDown {
                    Text("DD")
                        .font(.system(size: FontSize.xs))
                        .padding(Spacing.xs)
                        .background(Color.orange)
                        .cornerRadius(3)
                }
            }
            
            Text("Bet: $\(bet)")
                .font(.system(size: FontSize.sm))
                .foregroundColor(.gray)
            
            if !result.isEmpty {
                Text(result)
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(resultColor)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var resultColor: Color {
        switch result.lowercased() {
        case "win", "blackjack": return .green
        case "lose", "bust": return .red
        case "push": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Statistics Card
struct StatisticsCardView: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: FontSize.xs))
                .foregroundColor(.gray)
            Text("\(value)")
                .font(.system(size: FontSize.lg, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

