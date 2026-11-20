# roll-the-dice

Two six-sided dice in your browser. Tap anywhere to roll.

**Live:** <https://igorrosenberg.github.io/roll-the-dice/>

## Features

- Tap anywhere on the screen to roll both dice.
- Settings (gear icon, top right), saved in the browser:
  - **Fake delay**: 1 to 4999 ms (default 200). The dice tumble for this long before showing the result.
  - **Vibrate**: buzz while the dice roll (off by default). Works where the browser supports vibration, mainly Android; iPhones and desktops ignore it.
- Installable PWA ("Add to Home Screen" / "Install app") that works offline once opened.

## Local development

Requires Flutter (stable).

```sh
flutter pub get
flutter test
flutter run -d chrome
flutter build web    # output in build/web/
```

## Deploy

Every push to `main` builds the web app and publishes it to GitHub Pages
via [`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml).
No other branch deploys.
