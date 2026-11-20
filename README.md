# roll-the-dice

A one-page Flutter app for Android and the web that shows two six-sided dice.
Tap anywhere on the screen and both dice instantly show a new random face.

## Run

```sh
flutter pub get
flutter run          # with an Android device or emulator connected
flutter test
flutter build apk    # APK lands in build/app/outputs/flutter-apk/
flutter run -d chrome
flutter build web    # site lands in build/web/
```

## Web

Every push to `main` deploys the web build to GitHub Pages at
<https://igorrosenberg.github.io/roll-the-dice/>. It is an installable PWA
("Add to Home Screen" / "Install app") and works offline once opened.
Vibration works in Android browsers only; iPhones and desktops ignore it.

Built with Flutter 3.50 (stable).
