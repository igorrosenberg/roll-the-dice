import 'package:vibration/vibration.dart';

void vibrate(int durationMs) {
  Vibration.vibrate(duration: durationMs).catchError((_) {});
}

void cancel() {
  Vibration.cancel().catchError((_) {});
}
