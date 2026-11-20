// Used outside the browser (e.g. `flutter test` on the Dart VM), where there
// is no vibration motor to drive.
void vibrate(int durationMs) {}

void cancel() {}

bool get isSupported => false;
