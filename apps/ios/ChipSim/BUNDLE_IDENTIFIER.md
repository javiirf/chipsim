# Bundle Identifier (App Store ID)

## Current Bundle Identifier

**`com.chipsimulator.app`**

This is the unique identifier for your iOS app in the App Store and Apple Developer system.

## Where It's Used

- **App Store Connect**: When you create your app listing
- **Apple Developer Portal**: For provisioning profiles and certificates
- **Firebase**: When configuring iOS app in Firebase Console
- **Xcode Project**: Set in Build Settings

## Important Notes

1. **Must be unique**: No other app can use this identifier
2. **Cannot be changed**: Once published to App Store, you cannot change it
3. **Reverse domain format**: Uses reverse domain notation (com.yourcompany.appname)
4. **Firebase setup**: Use this exact identifier when adding iOS app to Firebase

## For App Store Connect

When creating your app in App Store Connect:
- **Bundle ID**: `com.chipsimulator.app`
- **SKU**: Can be anything unique (e.g., `chip-simulator-ios`)
- **App Name**: Chip Simulator (or your preferred display name)

## For Firebase

When adding iOS app to Firebase Console:
1. Go to Project Settings > Your apps
2. Click "Add app" > iOS
3. Enter Bundle ID: `com.chipsimulator.app`
4. Download `GoogleService-Info.plist`
5. Add it to your Xcode project

