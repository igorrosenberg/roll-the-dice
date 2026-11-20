# roll-the-dice

One to nine six-sided dice in your browser. Tap anywhere to roll.

**Live:** <https://igorrosenberg.github.io/roll-the-dice/>

## Features

- Tap anywhere on the screen to roll all the dice.
- Settings (gear icon, top right), saved in the browser:
  - **Fake delay**: 1 to 4999 ms (default 200). The dice tumble for this long before showing the result.
  - **Number of dice**: 1 to 9 (default 2), laid out as big square dice in portrait or landscape.
  - **Sum of dice**: show the total in a circle below the dice (off by default).
  - **3D**: draw the dice as see-through blue cubes, like the app icon, that tumble in 3D for the fake delay (off by default).
  - **Vibrate**: buzz while the dice roll (off by default). Works where the browser supports vibration, mainly Android; iPhones and desktops ignore it.
- Installable PWA ("Add to Home Screen" / "Install app") that works offline once opened.

## Install on your phone

Open <https://igorrosenberg.github.io/roll-the-dice/> once while online, then:

**Android (Chrome)**
1. Tap the ⋮ menu, top right.
2. Tap **Install app** (on some versions, **Add to Home screen**), then **Install**.
3. Open "Dice" from your home screen or app drawer. It runs full screen and works offline.

Samsung Internet and Edge offer the same option in their menus. Firefox on Android
can add a home-screen shortcut, but it can't vibrate.

**iPhone / iPad (Safari)**
1. Tap the **Share** button (square with an up arrow).
2. Scroll down and tap **Add to Home Screen**, then **Add**.
3. Open "Dice" from your home screen.

On iOS 16.4 and later, Chrome and Edge also show **Add to Home Screen** in their
Share menu. iPhones don't support web vibration, so the Vibrate setting does nothing there.

To remove it, delete it like any other app.

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
