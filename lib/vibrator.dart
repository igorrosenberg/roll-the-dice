import 'package:vibration/vibration.dart';

/// Starts and stops the phone's vibration motor.
abstract class Vibrator {
  void start(int durationMs);
  void stop();
}

class DeviceVibrator implements Vibrator {
  const DeviceVibrator();

  @override
  void start(int durationMs) {
    Vibration.vibrate(duration: durationMs).catchError((_) {});
  }

  @override
  void stop() {
    Vibration.cancel().catchError((_) {});
  }
}
