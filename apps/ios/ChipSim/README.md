# Chip Simulator iOS App

Native iOS version of the Chip Simulator app, built with SwiftUI.

## Setup Instructions

### 1. Firebase Configuration

1. Download `GoogleService-Info.plist` from your Firebase project console
2. Add it to the Xcode project (drag into the project navigator)
3. Ensure it's added to the target

### 2. Firebase SDK

The project uses Firebase via Swift Package Manager. To add:

1. In Xcode, go to File > Add Package Dependencies
2. Add: `https://github.com/firebase/firebase-ios-sdk`
3. Select these products:
   - FirebaseAuth
   - FirebaseDatabase
   - FirebaseCore

### 3. Audio Files

Add the following audio files to the project (they live in `apps/web/`):
- `place-your-bets-please-female-voice-28110.mp3`
- `carddrop2-92718.mp3`
- `casino-ambiance-19130.mp3` (for background music)

**To add audio files in Xcode:**
1. Drag the `.mp3` files from `apps/web/` into the Xcode project navigator
2. Make sure "Copy items if needed" is checked
3. Ensure the files are added to the ChipSim target
4. The files should appear in the project bundle and be accessible at runtime

Or update `AudioService.swift` to use different audio files.

### 4. Project Structure

```
ChipSim/
├── ChipSimApp.swift          # App entry point
├── Models/
│   ├── Player.swift          # Player models
│   ├── Statistics.swift      # Statistics models
│   ├── PokerGame.swift       # Poker game logic
│   └── BlackjackGame.swift   # Blackjack game logic
├── Services/
│   ├── FirebaseService.swift # Firebase integration
│   └── AudioService.swift    # Audio playback
└── Views/
    ├── HomeView.swift        # Main menu
    ├── PokerSetupView.swift  # Poker setup
    ├── PokerGameView.swift   # Poker game
    ├── BlackjackSetupView.swift # Blackjack setup
    └── BlackjackGameView.swift  # Blackjack game
```

## Features Implemented

- ✅ Poker (Texas Hold'em) game with full betting logic
- ✅ Blackjack game (single, two hands, multiplayer modes)
- ✅ Firebase cloud storage integration
- ✅ Audio service for sound effects
- ✅ Statistics tracking
- ✅ Home screen with game selection
- ✅ Navigation between games

## Next Steps

1. Add Firebase configuration file
2. Add audio files to project
3. Test on device/simulator
4. Enhance UI/UX as needed
5. Add more game features (card dealing visualization, etc.)

## Notes

- The app uses the same Firebase project as the web version
- Game logic matches the web version's JavaScript implementation
- Some features may need refinement based on testing

