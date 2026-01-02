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
                    
                    Toggle("Background Music", isOn: $audioService.musicEnabled)
                    
                    if audioService.musicEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Music Volume")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Slider(value: $audioService.musicVolume, in: 0...1)
                                
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            
                            Text("\(Int(audioService.musicVolume * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
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

