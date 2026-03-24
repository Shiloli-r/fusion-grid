# Fusion Grid

Fusion Grid is an offline Flutter number-merging puzzle game inspired by swipe-and-merge gameplay.

## Features

- Classic 4x4 merge gameplay
- Smooth swipe movement and tile animations
- Local best score persistence
- Settings for sound and vibration
- Undo (last move only, unlimited use over time)
- One-time shuffle power-up per game
- Multiple modes:
  - Classic
  - 4s Rush
  - Time Attack (2-minute mode)

## Tech Stack

- Flutter
- Dart
- GetX (state management and routing)
- shared_preferences (local persistence)

## Run the App

```bash
flutter pub get
flutter run
```

## Run Tests

```bash
flutter test
```

## Android Release Build (Play Store AAB)

This project is configured for signed Android release builds via:

- `android/key.properties`
- `android/app/upload-keystore.jks`

Build the Play Store bundle:

```bash
flutter build appbundle --release
```

Output file:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Notes

- Keep `android/key.properties` and `.jks` files private.
- Do not commit signing secrets to source control.

## Privacy Policy (Play Store)

This repository includes a policy draft at:

- `PRIVACY_POLICY.md`

Update the contact email and effective date before publishing.

## Deploy Privacy Policy to GitHub Pages

Use this quick flow to publish `PRIVACY_POLICY.md` and get a public URL for Play Console.

1) Create a public GitHub repository and push this project.
2) In GitHub, go to:
   - `Settings` -> `Pages`
3) Under **Build and deployment**:
   - Source: `Deploy from a branch`
   - Branch: `main` (or your default branch)
   - Folder: `/ (root)`
4) Click **Save** and wait for Pages to publish.
5) Your site URL will look like:
   - `https://<your-username>.github.io/<repo-name>/`
6) Open the published URL for the privacy policy file:
   - `https://<your-username>.github.io/<repo-name>/PRIVACY_POLICY.md`

### Recommended cleaner URL

This repo already includes:

- `docs/privacy-policy.html`

For a cleaner final URL:

1) In GitHub Pages settings, select:
   - Branch: `main` (or default branch)
   - Folder: `/docs`
2) Use this URL in Play Console:
   - `https://<your-username>.github.io/<repo-name>/privacy-policy.html`
