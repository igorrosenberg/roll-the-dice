import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User settings, saved on the device so they survive app restarts.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._delayMs, this._vibrate);

  static const int defaultDelayMs = 200;
  static const int maxDelayMsExclusive = 5000;
  static const String _delayKey = 'fakeDelayMs';
  static const String _vibrateKey = 'vibrate';

  final SharedPreferences _prefs;
  int _delayMs;
  bool _vibrate;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_delayKey);
    return AppSettings._(
      prefs,
      stored != null && isValidDelay(stored) ? stored : defaultDelayMs,
      prefs.getBool(_vibrateKey) ?? false,
    );
  }

  /// A delay must be a positive integer below 5000 ms.
  static bool isValidDelay(int ms) => ms > 0 && ms < maxDelayMsExclusive;

  /// How long the dice roll before showing the result, in milliseconds.
  int get delayMs => _delayMs;

  /// Whether the phone vibrates while the dice roll.
  bool get vibrate => _vibrate;

  set delayMs(int ms) {
    if (!isValidDelay(ms)) throw ArgumentError.value(ms, 'ms');
    if (ms == _delayMs) return;
    _delayMs = ms;
    _prefs.setInt(_delayKey, ms);
    notifyListeners();
  }

  set vibrate(bool on) {
    if (on == _vibrate) return;
    _vibrate = on;
    _prefs.setBool(_vibrateKey, on);
    notifyListeners();
  }
}
