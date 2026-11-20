import 'vibrator_stub.dart'
    if (dart.library.js_interop) 'vibrator_web.dart'
    as platform;

/// Starts and stops the phone's vibration motor.
abstract class Vibrator {
  /// Whether this browser can vibrate at all.
  bool get isSupported;

  void start(int durationMs);
  void stop();
}

/// Vibrates through the browser's Vibration API. Only Chromium-based Android
/// browsers have it: Firefox, iPhones and desktops don't.
class DeviceVibrator implements Vibrator {
  const DeviceVibrator();

  @override
  bool get isSupported => platform.isSupported;

  @override
  void start(int durationMs) => platform.vibrate(durationMs);

  @override
  void stop() => platform.cancel();
}
