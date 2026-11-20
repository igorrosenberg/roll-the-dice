import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User settings, saved on the device so they survive app restarts.
class AppSettings extends ChangeNotifier {
  AppSettings._(
    this._prefs,
    this._delayMs,
    this._vibrate,
    this._diceCount,
    this._showSum,
  );

  static const int defaultDelayMs = 200;
  static const int maxDelayMsExclusive = 5000;
  static const String _delayKey = 'fakeDelayMs';
  static const String _vibrateKey = 'vibrate';
  static const int defaultDiceCount = 2;
  static const int minDiceCount = 1;
  static const int maxDiceCount = 9;
  static const String _diceCountKey = 'diceCount';
  static const String _showSumKey = 'showSum';

  final SharedPreferences _prefs;
  int _delayMs;
  bool _vibrate;
  int _diceCount;
  bool _showSum;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_delayKey);
    final storedCount = prefs.getInt(_diceCountKey);
    return AppSettings._(
      prefs,
      stored != null && isValidDelay(stored) ? stored : defaultDelayMs,
      prefs.getBool(_vibrateKey) ?? false,
      storedCount != null && isValidDiceCount(storedCount)
          ? storedCount
          : defaultDiceCount,
      prefs.getBool(_showSumKey) ?? false,
    );
  }

  /// A delay must be a positive integer below 5000 ms.
  static bool isValidDelay(int ms) => ms > 0 && ms < maxDelayMsExclusive;

  /// The number of dice must be 1 to 9.
  static bool isValidDiceCount(int n) => n >= minDiceCount && n <= maxDiceCount;

  /// How long the dice roll before showing the result, in milliseconds.
  int get delayMs => _delayMs;

  /// Whether the phone vibrates while the dice roll.
  bool get vibrate => _vibrate;

  /// How many dice the main page shows and rolls.
  int get diceCount => _diceCount;

  /// Whether the main page shows the total of the dice, in a circle below
  /// them.
  bool get showSum => _showSum;

  set diceCount(int n) {
    if (!isValidDiceCount(n)) throw ArgumentError.value(n, 'n');
    if (n == _diceCount) return;
    _diceCount = n;
    _prefs.setInt(_diceCountKey, n);
    notifyListeners();
  }

  set showSum(bool on) {
    if (on == _showSum) return;
    _showSum = on;
    _prefs.setBool(_showSumKey, on);
    notifyListeners();
  }

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
