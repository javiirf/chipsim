//
//  PokerComponents.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

// MARK: - Chip Display
struct ChipView: View {
    let amount: Int
    let color: ChipColor
    
    enum ChipColor {
        case white, red, blue, green, orange, black, gold
        
        var gradient: LinearGradient {
            switch self {
            case .white: return ChipColors.whiteChip
            case .red: return ChipColors.redChip
            case .blue: return ChipColors.blueChip
            case .green: return ChipColors.greenChip
            case .orange: return ChipColors.orangeChip
            case .black: return ChipColors.blackChip
            case .gold: return ChipColors.goldChip
            }
        }
        
        var borderColor: Color {
            switch self {
            case .white: return ChipColors.whiteChipBorder
            case .red: return ChipColors.redChipBorder
            case .blue: return ChipColors.blueChipBorder
            case .green: return ChipColors.greenChipBorder
            case .orange: return ChipColors.orangeChipBorder
            case .black: return ChipColors.blackChipBorder
            case .gold: return ChipColors.goldChipBorder
            }
        }
        
        var textColor: Color {
            switch self {
            case .white: return ChipColors.whiteChipText
            case .red: return ChipColors.redChipText
            case .blue: return ChipColors.blueChipText
            case .green: return ChipColors.greenChipText
            case .orange: return ChipColors.orangeChipText
            case .black: return ChipColors.blackChipText
            case .gold: return ChipColors.goldChipText
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(color.borderColor, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            Text("$\(amount)")
                .font(.system(size: FontSize.xs, weight: .bold))
                .foregroundColor(color.textColor)
        }
    }
}

// MARK: - Position Badge
struct PositionBadge: View {
    let position: String
    
    var body: some View {
        Text(position)
            .font(.system(size: FontSize.xs, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(3)
    }
    
    private var badgeColor: Color {
        switch position {
        case "D": return .blue
        case "SB": return .gray
        case "BB": return .orange
        default: return .yellow
        }
    }
}

// MARK: - Action Button
struct PokerActionButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case fold, check, call, raise, allIn
        
        var color: Color {
            switch self {
            case .fold: return .red
            case .check: return .green
            case .call: return .blue
            case .raise: return .yellow
            case .allIn: return .orange
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm)
                .background(style.color)
                .cornerRadius(8)
        }
    }
}

// MARK: - Raise Chip Button
struct RaiseChipButton: View {
    let label: String
    let amount: Int
    let chipColor: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(label)
                    .font(.system(size: FontSize.xs, weight: .bold))
                Text("$\(amount)")
                    .font(.system(size: FontSize.xs))
            }
            .foregroundColor(getChipTextColor(chipColor))
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background(getChipGradient(chipColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(getChipColor(), lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
    
    private func getChipColor() -> Color {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChipBorder
        case "red": return ChipColors.redChipBorder
        case "blue": return ChipColors.blueChipBorder
        case "green": return ChipColors.greenChipBorder
        case "orange": return ChipColors.orangeChipBorder
        case "black": return ChipColors.blackChipBorder
        case "gold": return ChipColors.goldChipBorder
        default: return ChipColors.goldChipBorder
        }
    }
    
    private func getChipGradient(_ chipColor: String) -> LinearGradient {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChip
        case "red": return ChipColors.redChip
        case "blue": return ChipColors.blueChip
        case "green": return ChipColors.greenChip
        case "orange": return ChipColors.orangeChip
        case "black": return ChipColors.blackChip
        case "gold": return ChipColors.goldChip
        default: return ChipColors.goldChip
        }
    }
    
    private func getChipTextColor(_ chipColor: String) -> Color {
        switch chipColor.lowercased() {
        case "white": return ChipColors.whiteChipText
        case "red": return ChipColors.redChipText
        case "blue": return ChipColors.blueChipText
        case "green": return ChipColors.greenChipText
        case "orange": return ChipColors.orangeChipText
        case "black": return ChipColors.blackChipText
        case "gold": return ChipColors.goldChipText
        default: return ChipColors.goldChipText
        }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            Text(status)
                .font(.system(size: FontSize.xs))
                .foregroundColor(isActive ? .green : .gray)
        }
    }
}

// MARK: - Pot Display
struct PotDisplay: View {
    let amount: Int
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text("POT")
                .font(.system(size: FontSize.xs))
                .foregroundColor(.gray)
            Text("$\(amount)")
                .font(.system(size: FontSize.xl, weight: .bold))
                .foregroundColor(AppColors.gold)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.gold.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: AppColors.gold.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Street Indicator
struct StreetIndicator: View {
    let currentStreet: PokerStreet
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            StreetDot(street: .preflop, currentStreet: currentStreet)
            StreetDot(street: .flop, currentStreet: currentStreet)
            StreetDot(street: .turn, currentStreet: currentStreet)
            StreetDot(street: .river, currentStreet: currentStreet)
        }
    }
}

struct StreetDot: View {
    let street: PokerStreet
    let currentStreet: PokerStreet
    
    private let streetOrder: [PokerStreet] = [.preflop, .flop, .turn, .river]
    
    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 10, height: 10)
    }
    
    private var dotColor: Color {
        let currentIndex = streetOrder.firstIndex(of: currentStreet) ?? 0
        let dotIndex = streetOrder.firstIndex(of: street) ?? 0
        
        if dotIndex < currentIndex {
            return .green // Completed
        } else if dotIndex == currentIndex {
            return .yellow // Active
        } else {
            return .gray // Upcoming
        }
    }
}

// MARK: - Hand Log View
struct HandLogView: View {
    let actions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Hand Log")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(AppColors.gold)
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(actions, id: \.self) { action in
                        Text(action)
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxHeight: 120)
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

