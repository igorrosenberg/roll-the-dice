import 'vibrator_stub.dart'
    if (dart.library.js_interop) 'vibrator_web.dart'
    as platform;

/// Starts and stops the phone's vibration motor.
abstract class Vibrator {
  void start(int durationMs);
  void stop();
}

/// Vibrates through the browser's Vibration API (Android browsers only:
/// iPhones and desktops ignore it).
class DeviceVibrator implements Vibrator {
  const DeviceVibrator();

  @override
  void start(int durationMs) => platform.vibrate(durationMs);

  @override
  void stop() => platform.cancel();
}
