# Simple Games

**Simple Games** is a Flutter mobile application packed with calm, ad‑free games designed specifically for seniors. The focus is on large typography, high contrast visuals, and simple interactions so players can relax and enjoy quality experiences without the frustration of advertisements or paywalls.

## Games

- **Crossword** – Classic crossword experience with instant feedback and big, easy-to-read tiles.
- **Word Search** – Randomly generated 10×10 puzzles with rich overlaps, smart highlighting, and colorful word tracking.

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.10 or newer (any stable channel).
- Android Studio or Xcode if you want to run on Android/iOS respectively.
- An emulator/simulator or a physical device in developer mode.

### Install Dependencies

```bash
flutter pub get
```

### Run the App (Debug)

```bash
flutter run
```

- Use the `-d` flag to pick a specific device, e.g. `flutter run -d chrome` or `flutter run -d emulator-5554`.
- Hot reload (`r`) is enabled by default when running in debug mode.

### Build Release APK (Android)

```bash
flutter build apk --release
```

The signed APK will be created in `build/app/outputs/flutter-apk/` (you must configure signing for Play Store distribution).

### Build Release IPA (iOS)

```bash
flutter build ipa --release
```

Requires Xcode, a macOS machine, and appropriate signing certificates/profiles.
