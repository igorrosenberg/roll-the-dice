import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:roll_the_dice/main.dart';

int pipsIn(WidgetTester tester, String dieKey) => tester
    .widgetList(
      find.descendant(
        of: find.byKey(Key(dieKey)),
        matching: find.byKey(const Key('pip')),
      ),
    )
    .length;

void main() {
  testWidgets('shows two dice with 1 to 6 pips', (tester) async {
    await tester.pumpWidget(const RollTheDiceApp());
    expect(find.byType(Die), findsNWidgets(2));
    for (final k in ['dieLeft', 'dieRight']) {
      expect(pipsIn(tester, k), inInclusiveRange(1, 6));
    }
  });

  testWidgets('tapping anywhere rerolls both dice immediately', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DicePage(random: Random(42))));
    final seen = <(int, int)>{};
    for (var i = 0; i < 30; i++) {
      // Tap a corner, away from the dice.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(); // single frame: no animation delay
      final l = pipsIn(tester, 'dieLeft');
      final r = pipsIn(tester, 'dieRight');
      expect(l, inInclusiveRange(1, 6));
      expect(r, inInclusiveRange(1, 6));
      seen.add((l, r));
    }
    expect(seen.length, greaterThan(5));
  });

  for (var v = 1; v <= 6; v++) {
    testWidgets('face $v has $v pips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Die(value: v, key: const Key('d')),
        ),
      );
      expect(pipsIn(tester, 'd'), v);
    });
  }
}
