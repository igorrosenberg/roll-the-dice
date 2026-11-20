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
    this._showStats,
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
  static const String _showStatsKey = 'showStats';
  static const String _faceCountsKey = 'statFaceCounts';
  static const String _sumCountsKey = 'statSumCounts';

  final SharedPreferences _prefs;
  int _delayMs;
  bool _vibrate;
  int _diceCount;
  bool _showSum;
  bool _showStats;
  List<int> _faceCounts = const [];
  List<int> _sumCounts = const [];

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_delayKey);
    final storedCount = prefs.getInt(_diceCountKey);
    final settings = AppSettings._(
      prefs,
      stored != null && isValidDelay(stored) ? stored : defaultDelayMs,
      prefs.getBool(_vibrateKey) ?? false,
      storedCount != null && isValidDiceCount(storedCount)
          ? storedCount
          : defaultDiceCount,
      prefs.getBool(_showSumKey) ?? false,
      prefs.getBool(_showStatsKey) ?? false,
    );
    settings._faceCounts = _loadCounts(prefs, _faceCountsKey, 6);
    settings._sumCounts = _loadCounts(
      prefs,
      _sumCountsKey,
      settings.sumBucketCount,
    );
    return settings;
  }

  /// Stored counts, or zeros when they are missing or do not fit.
  static List<int> _loadCounts(SharedPreferences prefs, String key, int n) {
    final counts = prefs.getStringList(key)?.map(int.tryParse).toList();
    return List.unmodifiable(
      counts != null &&
              counts.length == n &&
              counts.every((c) => c != null && c >= 0)
          ? counts.cast<int>()
          : List.filled(n, 0),
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

  /// Whether the main page shows histograms of the rolls under the dice.
  bool get showStats => _showStats;

  /// How many times each face, 1 to 6, came up since the last reset. Every
  /// die of a roll counts.
  List<int> get faceCounts => _faceCounts;

  /// How many times each total came up since the last reset: one bucket per
  /// possible total, from [diceCount] (all ones) up to 6 × [diceCount].
  List<int> get sumCounts => _sumCounts;

  /// How many possible totals [diceCount] dice have.
  int get sumBucketCount => 5 * _diceCount + 1;

  /// Counts one finished roll of all the dice in both histograms.
  void recordRoll(List<int> values) {
    final faces = List.of(_faceCounts);
    for (final v in values) {
      faces[v - 1]++;
    }
    final sums = List.of(_sumCounts);
    sums[values.fold(0, (a, b) => a + b) - _diceCount]++;
    _saveStats(faces, sums);
  }

  /// Sets every bucket of both histograms back to 0.
  void resetStats() =>
      _saveStats(List.filled(6, 0), List.filled(sumBucketCount, 0));

  void _saveStats(List<int> faces, List<int> sums) {
    _faceCounts = List.unmodifiable(faces);
    _sumCounts = List.unmodifiable(sums);
    _prefs.setStringList(_faceCountsKey, [for (final c in faces) '$c']);
    _prefs.setStringList(_sumCountsKey, [for (final c in sums) '$c']);
    notifyListeners();
  }

  set showStats(bool on) {
    if (on == _showStats) return;
    _showStats = on;
    _prefs.setBool(_showStatsKey, on);
    notifyListeners();
  }

  set diceCount(int n) {
    if (!isValidDiceCount(n)) throw ArgumentError.value(n, 'n');
    if (n == _diceCount) return;
    _diceCount = n;
    _prefs.setInt(_diceCountKey, n);
    // The totals change with the number of dice: start a new count.
    resetStats();
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
