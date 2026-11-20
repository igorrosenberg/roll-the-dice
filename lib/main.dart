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

/// The main page: 1 to 9 six-sided dice (a setting, 2 by default). Tapping
/// anywhere rolls them all: they tumble for the "fake delay" set in settings, then show the result.
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

  late List<int> _values = _rollAll();
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

  List<int> _rollAll() =>
      List.generate(widget.settings.diceCount, (_) => _roll());

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    // Rebuild for a change of count or of the sum setting; reroll on a new count.
    setState(() {
      if (_values.length != widget.settings.diceCount) _values = _rollAll();
    });
  }

  bool get _rolling => _spin.isAnimating;

  @override
  void dispose() {
    if (_rolling) widget.vibrator.stop();
    widget.settings.removeListener(_onSettingsChanged);
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
      _values = _rollAll();
    }
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (widget.settings.vibrate) widget.vibrator.stop();
    _spin.reset();
    setState(() => _values = _rollAll());
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SettingsPage(settings: widget.settings, vibrator: widget.vibrator),
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

  /// Space between dice.
  static const double _gap = 24;

  /// Lays the dice out in the grid of rows and columns that gives the
  /// biggest square dice in [space], whatever its shape. An unfilled last
  /// row is centered.
  Widget _diceGrid(Size space) {
    final n = _values.length;
    final (cols, side) = diceGridFor(n, space, _gap);
    final rows = <Widget>[];
    for (var start = 0; start < n; start += cols) {
      final end = min(start + cols, n);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < end; i++) ...[
              if (i > start) const SizedBox(width: _gap),
              SizedBox.square(
                dimension: side,
                child: _tumbling(
                  Die(value: _values[i], key: Key('die$i')),
                  i.isEven ? 1 : -1,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: _gap),
            rows[r],
          ],
        ],
      ),
    );
  }

  /// The dice grid, with the total in a circle below it when the "Sum of
  /// dice" setting is on. The circle takes a fifth of the height at most.
  Widget _diceAndSum(Size space) {
    if (!widget.settings.showSum) return _diceGrid(space);
    final circle = max(0.0, min(min(space.height / 5, space.width), 120.0));
    final total = _values.fold(0, (a, b) => a + b);
    // Shrink the grid's space to its rows so the circle sits right under it.
    final n = _values.length;
    final gridSpace = Size(space.width, max(0.0, space.height - circle - _gap));
    final (cols, side) = diceGridFor(n, gridSpace, _gap);
    final rows = (n / cols).ceil();
    final gridHeight = rows * side + (rows - 1) * _gap;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: gridHeight,
            child: _diceGrid(Size(space.width, gridHeight)),
          ),
          const SizedBox(height: _gap),
          SizedBox.square(
            dimension: circle,
            child: SumCircle(total: total, dice: n),
          ),
        ],
      ),
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
                    child: LayoutBuilder(
                      builder: (context, box) => _diceAndSum(box.biggest),
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

/// The column count and die side that fit [n] square dice, [gap] apart, as
/// big as possible inside [space].
(int, double) diceGridFor(int n, Size space, double gap) {
  var best = (1, 0.0);
  for (var cols = 1; cols <= n; cols++) {
    final rows = (n / cols).ceil();
    final side = min(
      (space.width - gap * (cols - 1)) / cols,
      (space.height - gap * (rows - 1)) / rows,
    );
    if (side > best.$2) best = (cols, side);
  }
  return (best.$1, max(best.$2, 0.0));
}

/// The total of the dice, written big in a white circle.
class SumCircle extends StatelessWidget {
  const SumCircle({super.key, required this.total, required this.dice});

  final int total;
  final int dice;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sum of $dice dice: $total',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          key: const Key('sumCircle'),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FractionallySizedBox(
            widthFactor: 0.6,
            heightFactor: 0.5,
            child: FittedBox(
              child: Text(
                '$total',
                key: const Key('sumText'),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
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
