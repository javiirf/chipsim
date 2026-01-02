# Uploading ChipSim to App Store Connect

This guide walks you through uploading your ChipSim iOS app build to App Store Connect for TestFlight testing and App Store submission.

## Prerequisites

Before uploading, ensure you have:

1. ✅ **Apple Developer Account** (paid membership required for App Store distribution)
2. ✅ **App Record Created** in App Store Connect
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Create a new app record if you haven't already
   - Use Bundle ID: `com.chipsimulator.app`
   - Choose your app name, primary language, and SKU
3. ✅ **Code Signing Configured** (see `SIGNING_FIX.md` if you have issues)
4. ✅ **Xcode Project Ready**
   - Bundle Identifier: `com.chipsimulator.app`
   - Version: 1.0 (MARKETING_VERSION)
   - Build: 1 (CURRENT_PROJECT_VERSION)
   - Team: K436XFP9QZ

## Step 1: Prepare Your Build

### 1.1 Update Version and Build Numbers

Before each upload, increment your build number:

1. Open `ChipSim.xcodeproj` in Xcode
2. Select the **ChipSim** target
3. Go to the **General** tab
4. Update:
   - **Version**: Your app version (e.g., 1.0, 1.1, etc.)
   - **Build**: Increment this for each upload (e.g., 1, 2, 3, etc.)

Or edit `project.pbxproj` directly:
- `MARKETING_VERSION` = version number (shown to users)
- `CURRENT_PROJECT_VERSION` = build number (must be unique for each upload)

### 1.2 Configure for App Store Distribution

1. In Xcode, select **Product → Scheme → Edit Scheme...**
2. Select **Archive** from the left sidebar
3. Set **Build Configuration** to **Release**
4. Click **Close**

### 1.3 Verify Signing Settings

1. Select the **ChipSim** target
2. Go to **Signing & Capabilities** tab
3. Ensure:
   - ✅ **Automatically manage signing** is checked
   - ✅ Your **Team** (K436XFP9QZ) is selected
   - ✅ **Bundle Identifier** is `com.chipsimulator.app`
   - ✅ **Provisioning Profile** shows "Xcode Managed Profile"

For App Store distribution, you need:
- **Distribution Certificate** (Apple Distribution)
- **App Store Provisioning Profile** (Xcode will create this automatically)

## Step 2: Archive Your App

### 2.1 Clean Build Folder

1. **Product → Clean Build Folder** (Shift+Cmd+K)
2. Wait for the clean to complete

### 2.2 Create Archive

1. Select **Any iOS Device** or **Generic iOS Device** from the device menu (top toolbar)
   - ⚠️ **Important**: Don't select a simulator - archives must be built for a real device
2. **Product → Archive** (or Cmd+B then Product → Archive)
3. Wait for the archive to build (this may take a few minutes)
4. The **Organizer** window will open automatically when the archive is complete

## Step 3: Upload to App Store Connect

### Method 1: Upload via Xcode (Recommended)

1. In the **Organizer** window (Window → Organizer if it didn't open)
2. Select your archive (should show today's date)
3. Click **Distribute App**
4. Select **App Store Connect**
5. Click **Next**
6. Choose **Upload**
7. Click **Next**
8. Review the **App Store Connect Distribution Options**:
   - ✅ **Include bitcode** (if applicable)
   - ✅ **Upload your app's symbols** (recommended for crash reporting)
9. Click **Next**
10. Review the signing options:
    - Usually: **Automatically manage signing**
    - Xcode will select the appropriate distribution certificate
11. Click **Next**
12. Review the summary and click **Upload**
13. Wait for the upload to complete (progress shown in Organizer)
14. You'll see "Upload Successful" when done

### Method 2: Upload via Transporter App

1. In Xcode Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Click **Next**
5. Choose **Export**
6. Click **Next**
7. Select a location to save the `.ipa` file
8. Click **Export**
9. Open **Transporter** app (download from Mac App Store if needed)
10. Drag the `.ipa` file into Transporter
11. Click **Deliver**
12. Wait for upload to complete

### Method 3: Upload via Command Line (Transporter)

```bash
# Install Transporter command line tool (if not already installed)
# Download from: https://apps.apple.com/us/app/transporter/id1450874784

# Upload using altool (deprecated but still works)
xcrun altool --upload-app \
  --type ios \
  --file "/path/to/your/app.ipa" \
  --username "your-apple-id@example.com" \
  --password "@keychain:Application Loader: your-apple-id@example.com"

# Or use Transporter CLI (newer method)
xcrun altool --upload-app \
  --type ios \
  --file "/path/to/your/app.ipa" \
  --apiKey "YOUR_API_KEY" \
  --apiIssuer "YOUR_ISSUER_ID"
```

## Step 4: Verify Upload in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → Select **ChipSim**
3. Go to **TestFlight** tab (for beta testing) or **App Store** tab (for submission)
4. Your build will appear in the builds list
5. Status will show:
   - **Processing** - Apple is processing your build (usually 10-30 minutes)
   - **Ready to Submit** - Build is processed and ready
   - **Invalid Binary** - There's an issue (check email for details)

### Processing Time

- First upload: Usually 30-60 minutes
- Subsequent uploads: Usually 10-30 minutes
- You'll receive an email when processing is complete

## Step 5: Common Issues and Solutions

### Issue: "No Devices" or "No Provisioning Profiles" Error

**This is the most common issue!** If you see:
```
Communication with Apple failed
Your team has no devices from which to generate a provisioning profile.
Xcode couldn't find any iOS App Development provisioning profiles matching 'com.chipsimulator.app'.
```

**Solution**: See the detailed guide in `APP_STORE_SIGNING_FIX.md` for step-by-step instructions.

**Quick Fix**:
1. Register at least one device (connect iPhone/iPad to Mac, or add UDID manually)
2. Ensure you have an **Apple Distribution** certificate (Xcode → Settings → Accounts → Manage Certificates)
3. Verify signing settings in Xcode (Signing & Capabilities tab)
4. Make sure you're building for **"Any iOS Device"** (not a simulator)

### Issue: "No suitable application records were found"

**Solution**: 
- Create an app record in App Store Connect first
- Ensure the Bundle ID matches exactly: `com.chipsimulator.app`
- Go to App Store Connect → My Apps → + (Create App)

### Issue: "Invalid Bundle Identifier"

**Solution**:
- Verify Bundle ID in Xcode matches App Store Connect
- Check that the Bundle ID is registered in your Apple Developer account
- Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)

### Issue: "Missing Compliance"

**Solution**:
- If your app uses encryption, you may need to complete export compliance
- In App Store Connect, go to your app → App Store → Compliance
- Answer the encryption questions

### Issue: "Invalid Binary" - Missing Required Icon

**Solution**:
- Ensure you have app icons in `Assets.xcassets/AppIcon.appiconset`
- Required sizes:
  - 1024x1024 (App Store)
  - 60x60, 120x120 (iPhone)
  - 76x76, 152x152 (iPad)

### Issue: "Invalid Binary" - Missing Privacy Descriptions

**Solution**:
- Add privacy descriptions in `Info.plist` for any permissions you use
- Common keys:
  - `NSLocationWhenInUseUsageDescription`
  - `NSCameraUsageDescription`
  - `NSMicrophoneUsageDescription`
  - `NSPhotoLibraryUsageDescription`

### Issue: Build Fails to Upload

**Solution**:
- Check your internet connection
- Try uploading again (sometimes network issues cause failures)
- Use Transporter app for more reliable uploads
- Check Xcode Console for detailed error messages

### Issue: "Code Signing Failed"

**Solution**:
- See `SIGNING_FIX.md` for detailed signing troubleshooting
- Ensure you have an **Apple Distribution** certificate
- Xcode should create this automatically when you select "Automatically manage signing"

## Step 6: After Upload

### For TestFlight (Beta Testing)

1. Once build shows "Ready to Submit" in TestFlight:
2. Go to **TestFlight** tab in App Store Connect
3. Add testers (internal or external)
4. Add build notes describing what's new
5. Submit for beta review (if using external testers)

### For App Store Submission

1. Once build shows "Ready to Submit":
2. Go to **App Store** tab in App Store Connect
3. Create a new version or update existing
4. Select your build from the dropdown
5. Complete all required metadata:
   - Screenshots (required for each device size)
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL (if required)
   - App category
6. Submit for review

## Version and Build Number Guidelines

- **Version (MARKETING_VERSION)**: 
  - Shown to users (e.g., 1.0, 1.1, 2.0)
  - Increment for feature releases
  - Format: Major.Minor.Patch (e.g., 1.0.0)

- **Build (CURRENT_PROJECT_VERSION)**:
  - Internal identifier
  - Must be unique for each upload
  - Increment for every upload, even if version stays the same
  - Can be any number (1, 2, 3, ... or 1.0.0, 1.0.1, etc.)

**Example**:
- Version 1.0, Build 1 (first upload)
- Version 1.0, Build 2 (bug fix, same version)
- Version 1.1, Build 3 (new features)

## Additional Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Xcode Help](https://help.apple.com/xcode/)

## Checklist Before Upload

- [ ] Version and build numbers are set correctly
- [ ] Code signing is configured (Automatic signing enabled)
- [ ] App icons are included (1024x1024 required)
- [ ] Privacy descriptions added to Info.plist (if needed)
- [ ] App record created in App Store Connect
- [ ] Bundle ID matches App Store Connect
- [ ] Archive built for "Any iOS Device" (not simulator)
- [ ] Build is in Release configuration
- [ ] All required assets are included
- [ ] Firebase configuration is correct
- [ ] Audio files are included in bundle

## Next Steps After First Upload

1. Wait for processing email (usually 30-60 minutes)
2. Check App Store Connect for build status
3. Add TestFlight testers (optional)
4. Complete App Store listing information
5. Submit for App Review when ready

---

**Note**: The first upload creates a beta version automatically. Subsequent uploads update the existing version or create new versions based on your version number.

