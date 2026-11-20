import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'settings.dart';
import 'settings_page.dart';
import 'vibrator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(RollTheDiceApp(settings: settings));
}

class RollTheDiceApp extends StatelessWidget {
  const RollTheDiceApp({
    super.key,
    required this.settings,
    this.vibrator = const DeviceVibrator(),
  });

  final AppSettings settings;
  final Vibrator vibrator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roll the Dice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: DicePage(random: Random(), settings: settings, vibrator: vibrator),
    );
  }
}

/// The main page: two six-sided dice. Tapping anywhere rolls both: they
/// tumble for the "fake delay" set in settings, then show the result.
class DicePage extends StatefulWidget {
  const DicePage({
    super.key,
    required this.random,
    required this.settings,
    this.vibrator = const DeviceVibrator(),
  });

  final Random random;
  final AppSettings settings;
  final Vibrator vibrator;

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  /// How often the faces change while rolling.
  static const _faceChangeMs = 70;

  late int _left = _roll();
  late int _right = _roll();
  // The roll length is a user setting, so keep it even when the phone asks
  // for shorter animations (Android "Remove animations", battery saver).
  late final AnimationController _spin =
      AnimationController(
          vsync: this,
          animationBehavior: AnimationBehavior.preserve,
        )
        ..addListener(_onTick)
        ..addStatusListener(_onStatus);
  int _lastFaceChangeMs = 0;

  int _roll() => widget.random.nextInt(6) + 1;

  bool get _rolling => _spin.isAnimating;

  @override
  void dispose() {
    if (_rolling) widget.vibrator.stop();
    _spin.dispose();
    super.dispose();
  }

  void _startRoll() {
    if (_rolling) return;
    final delay = widget.settings.delayMs;
    if (widget.settings.vibrate) widget.vibrator.start(delay);
    _lastFaceChangeMs = 0;
    _spin.duration = Duration(milliseconds: delay);
    _spin.forward(from: 0);
  }

  void _onTick() {
    final elapsedMs = (_spin.value * widget.settings.delayMs).round();
    if (elapsedMs - _lastFaceChangeMs >= _faceChangeMs) {
      _lastFaceChangeMs = elapsedMs;
      _left = _roll();
      _right = _roll();
    }
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (widget.settings.vibrate) widget.vibrator.stop();
    _spin.reset();
    setState(() {
      _left = _roll();
      _right = _roll();
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(settings: widget.settings),
      ),
    );
  }

  Widget _tumbling(Widget die, double direction) {
    final t = _spin.value;
    // A full turn or two that slows down, with a little bounce in size.
    final angle = direction * 2 * pi * 2 * Curves.easeOut.transform(t);
    final scale = 1 - 0.15 * sin(pi * t);
    return Transform.rotate(
      angle: angle,
      child: Transform.scale(scale: scale, child: die),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('tapArea'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _startRoll(),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _tumbling(
                            Die(value: _left, key: const Key('dieLeft')),
                            1,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _tumbling(
                            Die(value: _right, key: const Key('dieRight')),
                            -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: const Key('settingsButton'),
                icon: const Icon(Icons.settings),
                color: Colors.white,
                iconSize: 32,
                tooltip: 'Settings',
                onPressed: _openSettings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single die face drawn with pips.
class Die extends StatelessWidget {
  const Die({super.key, required this.value})
    : assert(value >= 1 && value <= 6);

  final int value;

  // Pip positions on a 3x3 grid (row, column) for each face.
  static const Map<int, List<(int, int)>> _pips = {
    1: [(1, 1)],
    2: [(0, 0), (2, 2)],
    3: [(0, 0), (1, 1), (2, 2)],
    4: [(0, 0), (0, 2), (2, 0), (2, 2)],
    5: [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)],
    6: [(0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 2)],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _pips[value]!;
    return Semantics(
      label: 'Die showing $value',
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: List.generate(3, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(3, (col) {
                    final on = pips.contains((row, col));
                    return Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.7,
                          heightFactor: 0.7,
                          child: on
                              ? const DecoratedBox(
                                  key: Key('pip'),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
