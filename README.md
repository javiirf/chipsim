# Chip Simulator Monorepo

Digital chip tracker for poker and blackjack. This repo holds the web PWA, the native iOS app, and a slot for Android.

## Apps
- `apps/web`: PWA (static HTML/JS/CSS) with Firebase config and assets.
- `apps/ios/ChipSim`: Native SwiftUI app (Xcode project).
- `apps/android`: Placeholder for the Android project; add your native or cross-platform app here.

## Features
- Texas Hold'em: 2-8 players, blinds, strict betting rules, burn prompts, series stats, undo.
- Blackjack: Single/two-hand or multiplayer, split up to 4, double/surrender, insurance, streaks/highscores.

## Quick Start
- Web local: `npx serve apps/web` or `firebase emulators:start --only hosting` after installing Firebase CLI.
- Web deploy: From repo root run `firebase deploy` once `apps/web/firebase-config.js` is set for your Firebase project.
- iOS: Open `apps/ios/ChipSim/ChipSim.xcodeproj` in Xcode, add your `GoogleService-Info.plist`, then run on simulator/device.
- Android: Scaffold your Android app inside `apps/android` and integrate the shared Firebase project/API.

## Firebase Notes
- `firebase.json` hosts from `apps/web` and points database rules to `apps/web/database.rules.json`.
- `.firebaserc` currently uses the `chip-simulator` project alias; swap it if you use another Firebase project.

## Project Structure
```
apps/
  web/                # Web PWA (HTML/JS/CSS, Firebase config, assets)
  ios/ChipSim/        # Xcode project for native iOS
  android/            # Placeholder for Android app
.firebase/            # Firebase CLI state
firebase.json         # Hosting + database rules config
.firebaserc           # Firebase project alias
LICENSE
MOBILE_DEPLOYMENT.md
README.md
```

## Disclaimer
For entertainment purposes only. This simulates casino chip tracking and does not involve real-money gambling. Success here does not imply real gambling success.

## License
MIT License - see `LICENSE` for details.
