//
//  ColorScheme.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

// Casino chip colors with proper gradients
struct ChipColors {
    // White chip ($1)
    static let whiteChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.97, green: 0.97, blue: 0.97),
            Color(red: 0.85, green: 0.85, blue: 0.85),
            Color(red: 0.94, green: 0.94, blue: 0.94)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let whiteChipBorder = Color(red: 0.67, green: 0.67, blue: 0.67)
    static let whiteChipText = Color(red: 0.13, green: 0.13, blue: 0.13)
    
    // Red chip ($5)
    static let redChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.33, blue: 0.33),
            Color(red: 0.8, green: 0.13, blue: 0.13),
            Color(red: 0.93, green: 0.2, blue: 0.2)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let redChipBorder = Color(red: 1.0, green: 0.53, blue: 0.53)
    static let redChipText = Color.white
    
    // Blue chip ($10)
    static let blueChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.33, green: 0.53, blue: 1.0),
            Color(red: 0.11, green: 0.29, blue: 0.85),
            Color(red: 0.2, green: 0.4, blue: 0.93)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let blueChipBorder = Color(red: 0.53, green: 0.67, blue: 1.0)
    static let blueChipText = Color.white
    
    // Green chip ($25)
    static let greenChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.27, green: 0.87, blue: 0.4),
            Color(red: 0.13, green: 0.63, blue: 0.27),
            Color(red: 0.2, green: 0.8, blue: 0.33)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let greenChipBorder = Color(red: 0.47, green: 1.0, blue: 0.6)
    static let greenChipText = Color.white
    
    // Orange chip ($50)
    static let orangeChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.53, blue: 0.2),
            Color(red: 0.8, green: 0.33, blue: 0.0),
            Color(red: 0.93, green: 0.4, blue: 0.07)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let orangeChipBorder = Color(red: 1.0, green: 0.67, blue: 0.4)
    static let orangeChipText = Color.white
    
    // Black chip ($100)
    static let blackChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.27, green: 0.27, blue: 0.27),
            Color(red: 0.07, green: 0.07, blue: 0.07),
            Color(red: 0.2, green: 0.2, blue: 0.2)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let blackChipBorder = Color(red: 0.83, green: 0.69, blue: 0.22) // Gold border
    static let blackChipText = Color(red: 0.83, green: 0.69, blue: 0.22) // Gold text
    
    // Gold chip ($500+)
    static let goldChip = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.8, blue: 0.0),
            Color(red: 0.8, green: 0.6, blue: 0.0),
            Color(red: 0.87, green: 0.67, blue: 0.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let goldChipBorder = Color(red: 1.0, green: 0.87, blue: 0.27)
    static let goldChipText = Color(red: 0.13, green: 0.13, blue: 0.13)
}

// UI Color Scheme
struct AppColors {
    // Background colors - brighter
    static let darkBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let darkerBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let cardBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    // Green felt background - brighter
    static let feltGreen = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.08, green: 0.35, blue: 0.08),
            Color(red: 0.05, green: 0.25, blue: 0.05),
            Color(red: 0.07, green: 0.3, blue: 0.07)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Accent colors - brighter
    static let gold = Color(red: 0.95, green: 0.8, blue: 0.3) // Brighter gold
    static let goldBright = Color(red: 1.0, green: 0.9, blue: 0.4)
    static let yellow = Color(red: 1.0, green: 0.9, blue: 0.3)
    
    // Status colors - brighter
    static let success = Color(red: 0.35, green: 0.95, blue: 0.5)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.3)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
    static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    // Additional bright colors
    static let purple = Color(red: 0.7, green: 0.4, blue: 1.0)
    static let cyan = Color(red: 0.2, green: 0.9, blue: 0.9)
    static let pink = Color(red: 1.0, green: 0.4, blue: 0.7)
}

