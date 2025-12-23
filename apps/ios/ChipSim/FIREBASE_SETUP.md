# Firebase Setup Instructions

## Step 1: Add Firebase SDK via Swift Package Manager

1. Open the project in Xcode: `ChipSim.xcodeproj`
2. In Xcode, go to **File** > **Add Package Dependencies...**
3. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
4. Click **Add Package**
5. Select these products (check the boxes):
   - ✅ **FirebaseCore**
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseDatabase**
6. Click **Add Package**
7. Wait for the packages to download and integrate

## Step 2: Add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one if needed)
3. Click the iOS app icon (or add iOS app)
4. Enter your bundle identifier: `com.chipsimulator.app`
5. Download the `GoogleService-Info.plist` file
6. Drag the file into your Xcode project (into the `ChipSim` folder)
7. Make sure "Copy items if needed" is checked
8. Make sure it's added to the target

## Step 3: Verify Setup

The project should now compile without Firebase import errors. The app will:
- Work offline using local storage
- Sync to Firebase when online and configured
- Use anonymous authentication automatically

## Troubleshooting

If you still see import errors:
1. Clean build folder: **Product** > **Clean Build Folder** (Shift+Cmd+K)
2. Close and reopen Xcode
3. Verify packages are added: Project Navigator > Package Dependencies

