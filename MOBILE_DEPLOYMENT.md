# Chip Simulator - Mobile App Deployment Guide

## Overview
This guide will help you build and publish the Chip Simulator app to both the Apple App Store (iOS) and Google Play Store (Android).

## Monorepo Layout
- Web PWA assets that feed Capacitor or any wrapper live in `apps/web/`.
- Native iOS project lives in `apps/ios/ChipSim/`.
- Android project slot is `apps/android/` (add your native or cross-platform project here).
Update any paths/commands in this guide to point at the monorepo locations.

---

## Prerequisites

### Required Software
1. **Node.js** (v18 or later) - [Download](https://nodejs.org/)
2. **npm** (comes with Node.js)
3. **Git** (optional but recommended)

### For iOS Development (Mac Required)
- **macOS** computer (required for iOS builds)
- **Xcode** 15+ from the Mac App Store
- **Apple Developer Account** ($99/year) - [Enroll](https://developer.apple.com/programs/enroll/)
- **CocoaPods**: `sudo gem install cocoapods`

### For Android Development
- **Android Studio** - [Download](https://developer.android.com/studio)
- **JDK 17** (bundled with Android Studio)
- **Google Play Developer Account** ($25 one-time) - [Sign Up](https://play.google.com/console)

---

## Step 1: Install Dependencies

Open a terminal in the project directory and run:

```bash
npm install
```

This installs Capacitor and all required plugins.

---

## Step 2: Initialize Capacitor Platforms

### Add iOS Platform (Mac only)
```bash
npx cap add ios
```

### Add Android Platform
```bash
npx cap add android
```

### Sync Web Code to Native Projects
```bash
npx cap sync
```

---

## Step 3: Configure Firebase for Mobile

### Enable Anonymous Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (chip-simulator)
3. Go to **Authentication** > **Sign-in method**
4. Enable **Anonymous** sign-in
5. Save

### Update Database Rules
Deploy the updated security rules:
```bash
npx firebase deploy --only database
```

---

## Step 4: Build for iOS (Mac Required)

### Open Xcode Project
```bash
npx cap open ios
```

### Configure Signing
1. In Xcode, select the project in the navigator
2. Go to **Signing & Capabilities** tab
3. Select your **Team** (Apple Developer account)
4. Xcode will create provisioning profiles automatically

### Update Bundle Identifier
Change `com.chipsimulator.app` to your unique identifier in:
- Xcode project settings
- `capacitor.config.json`

### Add App Icons
1. Create app icons in these sizes:
   - 1024x1024 (App Store)
   - 180x180, 120x120, 87x87, 80x80, 60x60, 58x58, 40x40, 29x29, 20x20
2. Add to `ios/App/App/Assets.xcassets/AppIcon.appiconset`

### Build Release
1. Select **Product** > **Archive**
2. Once complete, click **Distribute App**
3. Choose **App Store Connect**
4. Follow prompts to upload

---

## Step 5: Build for Android

### Open Android Studio Project
```bash
npx cap open android
```

### Update App Identifier
Change `com.chipsimulator.app` to your unique identifier in:
- `android/app/build.gradle` (applicationId)
- `capacitor.config.json`

### Add App Icons
Create icons in these densities and place in respective folders:
- `android/app/src/main/res/mipmap-mdpi/` (48x48)
- `android/app/src/main/res/mipmap-hdpi/` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/` (192x192)

### Generate Signed APK/Bundle
1. In Android Studio, go to **Build** > **Generate Signed Bundle/APK**
2. Select **Android App Bundle** (recommended) or **APK**
3. Create a new keystore or use existing
   - **IMPORTANT**: Save your keystore file and passwords securely!
4. Choose **release** build variant
5. Click **Finish**

The signed bundle will be in `android/app/release/`

---

## Step 6: Submit to App Stores

### Apple App Store

1. **App Store Connect Setup**
   - Go to [App Store Connect](https://appstoreconnect.apple.com/)
   - Click **My Apps** > **+** > **New App**
   - Fill in app details:
     - Name: Chip Simulator
     - Bundle ID: (your identifier)
     - SKU: chip-simulator
     - Access: Full Access

2. **App Information**
   - Category: Games > Casino
   - Privacy Policy URL (required)
   - Age Rating: 17+ (Simulated Gambling)

3. **App Version Details**
   - Screenshots (required sizes):
     - iPhone 6.7" (1290x2796)
     - iPhone 6.5" (1242x2688)
     - iPad 12.9" (2048x2732)
   - Description, keywords, promotional text
   - Support URL

4. **Submit for Review**
   - Upload build from Xcode
   - Complete all required fields
   - Submit for App Review (1-3 days typically)

### Google Play Store

1. **Play Console Setup**
   - Go to [Google Play Console](https://play.google.com/console)
   - Create new application
   - Fill in app details

2. **Store Listing**
   - App name: Chip Simulator
   - Short description (80 chars)
   - Full description (4000 chars)
   - Screenshots:
     - Phone (2-8 screenshots)
     - Tablet (optional)
   - Feature graphic (1024x500)
   - App icon (512x512)

3. **Content Rating**
   - Complete questionnaire
   - Select "Simulated Gambling" for rating
   - This usually results in Teen/17+ rating

4. **Privacy & Policy**
   - Privacy policy URL (required)
   - Data safety section

5. **Release**
   - Go to **Production** > **Create new release**
   - Upload your signed AAB file
   - Add release notes
   - Review and roll out

---

## Important Notes

### Gambling Disclaimer
Both app stores require gambling apps to:
- Include "simulated gambling" disclaimers
- Not involve real money
- Have appropriate age ratings
- Include responsible gaming information if applicable

Add this to your app description:
> "This app is for entertainment purposes only. It simulates casino chip tracking and does not involve real money gambling."

### Privacy Policy
You MUST have a privacy policy. Create one that covers:
- Data collected (anonymous user ID for cloud saves)
- How data is used (game state synchronization)
- Firebase services usage
- No personal data collection

### Updates
To push updates:
1. Make code changes
2. Run `npx cap sync`
3. Increment version in:
   - `package.json`
   - iOS: Xcode project settings
   - Android: `android/app/build.gradle`
4. Build and submit new version

---

## Troubleshooting

### iOS Build Issues
- **Signing errors**: Ensure your Apple Developer account is active and team is selected
- **Pod install fails**: Run `cd ios/App && pod install --repo-update`

### Android Build Issues
- **SDK not found**: Open Android Studio and install missing SDK components
- **Gradle sync fails**: Try **File** > **Invalidate Caches / Restart**

### Firebase Issues
- **Auth not working**: Ensure Anonymous auth is enabled in Firebase Console
- **Database writes fail**: Check that database rules are deployed

---

## Cost Summary

| Item | Cost |
|------|------|
| Apple Developer Program | $99/year |
| Google Play Developer | $25 one-time |
| Firebase (Spark Plan) | Free |

**Total to start**: ~$125

---

## Support

For Capacitor issues: [Capacitor Docs](https://capacitorjs.com/docs)
For Firebase issues: [Firebase Docs](https://firebase.google.com/docs)
