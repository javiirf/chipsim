# How to Add chipsim_logo.png to Your App

## Method 1: Using Xcode (Recommended - Easiest)

1. **Open your project in Xcode**:
   - Open `ChipSim.xcodeproj` in Xcode

2. **Navigate to Assets**:
   - In the Project Navigator (left sidebar), find and click on `Assets.xcassets`
   - Click on `AppIcon` in the asset catalog

3. **Add your icon**:
   - You'll see slots for different icon sizes
   - Find the **1024x1024** slot (usually at the top or bottom)
   - **Drag and drop** `chipsim_logo.png` into the 1024x1024 slot
   - OR click the slot and use the file picker to select `chipsim_logo.png`

4. **Verify**:
   - The icon should appear in the slot
   - Xcode will automatically use this for all required sizes

## Method 2: Manual File Placement

If you prefer to do it manually:

1. **Copy the file to the AppIcon folder**:
   ```bash
   cp chipsim_logo.png apps/ios/ChipSim/ChipSim/Assets.xcassets/AppIcon.appiconset/
   ```

2. **Update Contents.json** (Xcode will do this automatically, but if needed):
   - The file should reference `chipsim_logo.png` in the 1024x1024 slot

3. **Refresh in Xcode**:
   - Right-click on `Assets.xcassets` → "Add Files to ChipSim..."
   - Or just restart Xcode and it should pick up the file

## File Location

Your icon file should be placed here:
```
apps/ios/ChipSim/ChipSim/Assets.xcassets/AppIcon.appiconset/chipsim_logo.png
```

## Requirements

- **Size**: Must be exactly 1024x1024 pixels
- **Format**: PNG (preferred) or JPEG
- **No transparency**: iOS app icons should have a solid background (or at least look good on various backgrounds)
- **No rounded corners**: iOS will add these automatically

## After Adding

1. **Clean build folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Build the project**: Product → Build (Cmd+B)
3. **Check the icon**: Run the app on simulator/device to see the icon

## Troubleshooting

### Icon doesn't appear:
- Make sure the file is exactly 1024x1024 pixels
- Check that it's a valid PNG/JPEG file
- Try cleaning the build folder and rebuilding

### Icon looks wrong:
- Ensure it's square (1024x1024)
- Make sure there's no extra padding/margins
- iOS adds rounded corners automatically, so design should account for this

### Xcode doesn't recognize the file:
- Make sure the file is in the `AppIcon.appiconset` folder
- Check that it's added to the target (should be automatic)
- Try removing and re-adding through Xcode's UI

