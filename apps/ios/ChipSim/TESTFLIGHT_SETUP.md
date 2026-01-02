# TestFlight Setup Guide

## Current Status

You have a build uploaded: **1.0 (1)**
- Build is ready for testing
- You need to add test information and testers

## Step 1: Fill in "What to Test"

In the **"What to Test"** field, provide information about what you want testers to focus on.

### Example "What to Test" Text:

```
Welcome to ChipSim TestFlight!

Please test the following:

GAME FUNCTIONALITY:
- Poker (Texas Hold'em): Create a game, add players, place bets, complete hands
- Blackjack: Play single hand, two hands, and multiplayer modes
- Statistics: Check that stats are tracked and displayed correctly

FEATURES TO TEST:
- Chip tracking and betting mechanics
- Game state persistence (close and reopen app)
- Sound effects and audio controls
- Firebase sync (if logged in)
- Settings and data management

KNOWN ISSUES:
- None at this time

Please report any bugs or issues you encounter. Thank you for testing!
```

Or a shorter version:

```
Test the poker and blackjack games. Try creating games, placing bets, and checking statistics. Report any bugs or issues you find. Thanks for testing!
```

## Step 2: Add Testers

You have two options:

### Option A: Use Existing Group (Recommended)

You already have a group: **"NJ Development"** (Internal, 1 tester)

1. Click **"Add groups to this build"** or the **+** button
2. Select **"NJ Development"**
3. All testers in that group will get access

### Option B: Add Individual Testers

1. Click **"Add individual tester"** or the **+** button under "Individual Testers"
2. Enter tester email addresses (must be Apple IDs)
3. They'll receive an email invitation

## Step 3: Submit for Testing

After adding testers:

1. Click **"Save"** or **"Submit for Testing"** button
2. If this is your first external test, you may need to:
   - Complete Beta App Review (for external testers)
   - Answer questions about your app
   - Wait for Apple's approval (usually 24-48 hours)

## Internal vs External Testing

### Internal Testing (Your "NJ Development" group)
- ✅ **No review required** - Instant access
- ✅ Up to 100 testers (must be in your App Store Connect team)
- ✅ Testers get access immediately
- ✅ Use for quick testing with your team

### External Testing
- ⏳ **Requires Beta App Review** (24-48 hours)
- ✅ Up to 10,000 testers
- ✅ Can invite anyone with an Apple ID
- ✅ Use for broader testing

## Quick Setup Steps

1. **Fill "What to Test"**: Add testing instructions (see example above)
2. **Add Group**: Click to add "NJ Development" group
3. **Save**: Click "Save" or "Submit for Testing"
4. **Wait**: Internal testers get access immediately; external testers wait for review

## What Happens Next

### For Internal Testers:
- They'll receive an email invitation
- Can install via TestFlight app immediately
- No Apple review needed

### For External Testers:
- You'll need to submit for Beta App Review first
- Apple reviews your app (similar to App Store review)
- Once approved, testers can install

## Tips

- **Start with Internal Testing**: Test with your team first
- **Clear Instructions**: Help testers know what to focus on
- **Monitor Feedback**: Check TestFlight for crash reports and feedback
- **Update Builds**: Upload new builds as you fix issues

## Common Questions

**Q: Do I need to submit for review?**
- Internal testing: No
- External testing: Yes (Beta App Review)

**Q: How long does Beta App Review take?**
- Usually 24-48 hours
- Similar to App Store review process

**Q: Can I add more testers later?**
- Yes, you can add testers at any time

**Q: What if I find bugs?**
- Upload a new build with a higher build number
- Testers will see the update in TestFlight

## Next Steps After Testing

1. Collect feedback from testers
2. Fix any bugs or issues
3. Upload a new build (increment build number)
4. When ready, submit to App Store for review

