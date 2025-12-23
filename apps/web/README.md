# Chip Simulator Web (PWA)

Static HTML/JS/CSS build of the app. Firebase Hosting is configured to serve this directory.

## Run Locally
- Quick server: `npx serve apps/web`
- Firebase emulator: `firebase emulators:start --only hosting` (requires Firebase CLI)
- Update `firebase-config.js` with your Firebase project credentials before testing.

## Deploy
- From repo root: `firebase deploy` (uses `firebase.json` and `.firebaserc`)
- Database security rules live in `apps/web/database.rules.json`.

## Assets
- Audio files and images used by the web UI are stored alongside the HTML/JS/CSS in this folder.
