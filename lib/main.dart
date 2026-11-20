import 'dart:math';

import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const RollTheDiceApp());
}

class RollTheDiceApp extends StatelessWidget {
  const RollTheDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roll the Dice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: DicePage(random: Random()),
    );
  }
}

/// The single page: two six-sided dice. Tapping anywhere rerolls both.
class DicePage extends StatefulWidget {
  const DicePage({super.key, required this.random});

  final Random random;

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  late int _left = _roll();
  late int _right = _roll();

  int _roll() => widget.random.nextInt(6) + 1;

  void _rollBoth() {
    setState(() {
      _left = _roll();
      _right = _roll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      body: GestureDetector(
        key: const Key('tapArea'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _rollBoth(),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Die(value: _left, key: const Key('dieLeft')),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Die(value: _right, key: const Key('dieRight')),
                  ),
                ],
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
