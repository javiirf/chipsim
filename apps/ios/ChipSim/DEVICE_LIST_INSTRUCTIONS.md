# Device List File Instructions

## File Created
I've created `device-list.txt` in the correct format for Apple Developer portal.

## Format Required
Apple requires a **tab-delimited text file** with the following columns:
- Device Name
- Device ID (UDID)
- Platform

## How to Use

### Step 1: Get Your Device UDID
Use one of these methods:

**Method A: Using Finder**
1. Connect your iPhone to Mac via USB
2. Open Finder → Select your iPhone in sidebar
3. Click on device name/icon → UDID appears
4. Click to copy or right-click → Copy

**Method B: Using Xcode**
1. Connect iPhone to Mac via USB
2. Open Xcode → Window → Devices and Simulators (Shift+Cmd+2)
3. Select your iPhone → UDID appears → Click to copy

**Method C: From iPhone**
1. Settings → General → About
2. Find "Identifier" → Tap and hold to copy

### Step 2: Edit the File
1. Open `device-list.txt` in a text editor
2. Replace `YOUR_UDID_HERE` with your actual device UDID
3. Change "Cameron's iPhone" to whatever name you want (optional)
4. Save the file

### Step 3: Add More Devices (Optional)
Add additional devices, one per line:
```
Device Name	Device ID (UDID)	Platform
Cameron's iPhone	00008020-001D2D3E4C1A2B3C	iOS
Cameron's iPad	00008030-001E3F4G5D2B3C4D	iOS
Test iPhone	00008040-001F5G6H7E3D4E5F	iOS
```

**Important:** Use **TAB characters** between columns, not spaces!

### Step 4: Upload to Apple Developer Portal
1. Go to https://developer.apple.com/account/resources/devices/list
2. Click **Register a New Device**
3. Click **Register Multiple Devices**
4. Click **Choose File**
5. Select `device-list.txt`
6. Click **Continue** → **Submit**

## File Location
The file is located at:
```
/Users/cameronentezarian/Documents/GitHub/chipsim/apps/ios/ChipSim/device-list.txt
```

## Notes
- Maximum 100 devices per file
- Platform should be: `iOS`, `iPadOS`, `tvOS`, `watchOS`, or `visionOS`
- UDID format: Usually looks like `00008020-001D2D3E4C1A2B3C` (with or without dashes)
- The file must be tab-delimited, not comma-separated

