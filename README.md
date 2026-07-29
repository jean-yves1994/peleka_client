# Peleka Customer (peleka_client)

Complete, build-ready Flutter customer app for Peleka Courier (Kigali).
Native Android config is **pre-pinned** so `flutter build apk` just works:

- Android Gradle Plugin **8.7.0**
- Kotlin **2.1.0**
- Gradle wrapper **8.9**
- google-services **4.4.2**
- `minSdk = 23` (Firebase Auth), multidex on, Java 17

## One-time setup

```bash
flutter pub get

# Connect Firebase (generates lib/firebase_options.dart + android/app/google-services.json)
dart pub global activate flutterfire_cli
flutterfire configure        # pick your project, tick android + ios

# In Firebase Console → Authentication → Sign-in method → Phone → Enable
# Add a test number: +250788111222 / 123456
```

## Build the debug APK against your backend

```bash
# Expose your local backend (pick one):
ngrok http 3000                       # or: cloudflared tunnel --url http://localhost:3000

flutter build apk --debug --dart-define=API_BASE_URL=https://YOUR-TUNNEL-URL
# → build/app/outputs/flutter-apk/app-debug.apk
```

## Run on a device
```bash
flutter run --dart-define=API_BASE_URL=https://YOUR-TUNNEL-URL
```

## Notes
- Phone OTP needs Google Play Services → test on a real phone or a Google-Play emulator image.
  On plain emulators/Appetize use the Firebase **test number** to bypass real SMS.
- `lib/firebase_options.dart` ships as a safe placeholder; `main.dart` wraps
  `Firebase.initializeApp` in try/catch so a missing config never blanks the screen.
