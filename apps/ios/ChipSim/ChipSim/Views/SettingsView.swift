//
//  SettingsView.swift
//  ChipSim
//
//  Created by Cameron Entezarian on 12/22/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var audioService = AudioService.shared
    @State private var showClearDataAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Audio") {
                    Toggle("Sound Effects", isOn: $audioService.soundEnabled)
                        .onChange(of: audioService.soundEnabled) { _, newValue in
                            StorageService.shared.saveSoundEnabled(newValue)
                        }
                }
                
                Section("Data") {
                    Button(role: .destructive, action: {
                        showClearDataAlert = true
                    }) {
                        HStack {
                            Text("Clear All Data")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.1")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Chip Simulator")
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Legal") {
                    Text("For Entertainment Only")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("This app simulates casino chip tracking and does not involve real money gambling. No actual currency is wagered, won, or lost.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    StorageService.shared.clearAllData()
                }
            } message: {
                Text("This will delete all saved game data, statistics, and leaderboards. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
}

