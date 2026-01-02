#!/bin/bash

# Helper script to get iOS device UDID
# Usage: ./get-device-udid.sh

echo "Getting connected iOS device UDID..."
echo ""

# Method 1: Using system_profiler (works when device is connected via USB)
UDID=$(system_profiler SPUSBDataType 2>/dev/null | grep -A 11 "iPhone\|iPad" | grep "Serial Number" | head -1 | awk '{print $3}')

if [ -n "$UDID" ]; then
    echo "Device UDID found: $UDID"
    echo ""
    echo "To copy to clipboard, run:"
    echo "  echo '$UDID' | pbcopy"
    echo ""
    echo "Or manually copy the UDID above and add it at:"
    echo "  https://developer.apple.com/account/resources/devices/list"
else
    echo "No iOS device detected via USB."
    echo ""
    echo "Alternative methods to get UDID:"
    echo "1. Connect device to Mac → Open Finder → Select device → View UDID"
    echo "2. Open Xcode → Window → Devices and Simulators → Select device → Copy UDID"
    echo "3. On device: Settings → General → About → Copy the identifier"
    echo ""
    echo "Then add it manually at:"
    echo "  https://developer.apple.com/account/resources/devices/list"
fi

