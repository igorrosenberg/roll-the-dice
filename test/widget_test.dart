import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roll_the_dice/main.dart';
import 'package:roll_the_dice/settings.dart';
import 'package:roll_the_dice/vibrator.dart';

int pipsIn(WidgetTester tester, String dieKey) => tester
    .widgetList(
      find.descendant(
        of: find.byKey(Key(dieKey)),
        matching: find.byKey(const Key('pip')),
      ),
    )
    .length;

class FakeVibrator implements Vibrator {
  FakeVibrator({this.isSupported = true});

  @override
  final bool isSupported;

  final calls = <String>[];

  @override
  void start(int durationMs) => calls.add('start $durationMs');

  @override
  void stop() => calls.add('stop');
}

Future<AppSettings> loadSettings([Map<String, Object> stored = const {}]) {
  SharedPreferences.setMockInitialValues(stored);
  return AppSettings.load();
}

void main() {
  testWidgets('shows two dice with 1 to 6 pips', (tester) async {
    await tester.pumpWidget(RollTheDiceApp(settings: await loadSettings()));
    expect(find.byType(Die), findsNWidgets(2));
    for (final k in ['die0', 'die1']) {
      expect(pipsIn(tester, k), inInclusiveRange(1, 6));
    }
  });

  testWidgets('a tap rolls for the fake delay, then settles', (tester) async {
    final settings = await loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(random: Random(42), settings: settings),
      ),
    );
    final seen = <(int, int)>{};
    for (var i = 0; i < 20; i++) {
      await tester.tapAt(const Offset(300, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue, reason: 'still rolling');
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.hasRunningAnimations, isFalse, reason: 'settled');
      seen.add((pipsIn(tester, 'die0'), pipsIn(tester, 'die1')));
    }
    expect(seen.length, greaterThan(5));
  });

  testWidgets('vibrates during the roll only when enabled', (tester) async {
    final settings = await loadSettings({'vibrate': true, 'fakeDelayMs': 400});
    final vibrator = FakeVibrator();
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(
          random: Random(1),
          settings: settings,
          vibrator: vibrator,
        ),
      ),
    );
    await tester.tapAt(const Offset(300, 500));
    await tester.pump();
    expect(vibrator.calls, ['start 400']);
    await tester.pump(const Duration(milliseconds: 300));
    expect(vibrator.calls, ['start 400']);
    await tester.pump(const Duration(milliseconds: 150));
    expect(vibrator.calls, ['start 400', 'stop']);

    settings.vibrate = false;
    await tester.tapAt(const Offset(300, 500));
    await tester.pumpAndSettle();
    expect(vibrator.calls, ['start 400', 'stop']);
  });

  testWidgets('gear opens settings with defaults; edits persist', (
    tester,
  ) async {
    final settings = await loadSettings();
    await tester.pumpWidget(
      RollTheDiceApp(settings: settings, vibrator: FakeVibrator()),
    );
    final gear = tester.getCenter(find.byKey(const Key('settingsButton')));
    expect(
      gear.dx,
      greaterThan(
        tester.view.physicalSize.width / tester.view.devicePixelRatio - 100,
      ),
    );
    expect(gear.dy, lessThan(100));

    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    expect(find.text('Fake delay'), findsOneWidget);
    expect(find.text('Vibrate'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('vibrateSwitch')))
          .value,
      isFalse,
    );

    await tester.enterText(find.byKey(const Key('delayField')), '1500');
    await tester.tap(find.byKey(const Key('vibrateSwitch')));
    await tester.pump();
    expect(settings.delayMs, 1500);
    expect(settings.vibrate, isTrue);

    final reloaded = await AppSettings.load();
    expect(reloaded.delayMs, 1500);
    expect(reloaded.vibrate, isTrue);
  });

  testWidgets('vibrate switch is disabled when the browser cannot vibrate', (
    tester,
  ) async {
    final settings = await loadSettings({'vibrate': true});
    await tester.pumpWidget(
      RollTheDiceApp(
        settings: settings,
        vibrator: FakeVibrator(isSupported: false),
      ),
    );
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();

    final vibrateSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('vibrateSwitch')),
    );
    expect(vibrateSwitch.value, isFalse);
    expect(vibrateSwitch.onChanged, isNull);
    expect(find.textContaining("This browser can't vibrate"), findsOneWidget);
  });

  testWidgets('rejects delays that are not 1 to 4999', (tester) async {
    final settings = await loadSettings();
    await tester.pumpWidget(RollTheDiceApp(settings: settings));
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    for (final bad in ['0', '5000', '']) {
      await tester.enterText(find.byKey(const Key('delayField')), bad);
      await tester.pump();
      expect(find.text('Enter a whole number from 1 to 4999'), findsOneWidget);
      expect(settings.delayMs, 200);
      // The message sits under the row, not squeezed inside the field.
      expect(
        tester.getTopLeft(find.byKey(const Key('delayError'))).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byKey(const Key('delayField'))).dy,
        ),
      );
    }
    await tester.enterText(find.byKey(const Key('delayField')), '4999');
    await tester.pump();
    expect(find.text('Enter a whole number from 1 to 4999'), findsNothing);
    expect(settings.delayMs, 4999);
  });

  testWidgets(
    'roll lasts the fake delay even when the phone removes animations',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final settings = await loadSettings({
        'fakeDelayMs': 2000,
        'vibrate': true,
      });
      final vibrator = FakeVibrator();
      await tester.pumpWidget(
        MaterialApp(
          home: DicePage(
            random: Random(3),
            settings: settings,
            vibrator: vibrator,
          ),
        ),
      );
      await tester.tapAt(const Offset(300, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.hasRunningAnimations, isTrue, reason: 'still rolling');
      expect(vibrator.calls, ['start 2000']);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.hasRunningAnimations, isFalse, reason: 'settled');
      expect(vibrator.calls, ['start 2000', 'stop']);
    },
  );

  testWidgets('number of dice defaults to 2, offers 1 to 9 and persists', (
    tester,
  ) async {
    final settings = await loadSettings();
    expect(settings.diceCount, 2);
    await tester.pumpWidget(
      RollTheDiceApp(settings: settings, vibrator: FakeVibrator()),
    );
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    expect(find.text('Number of dice'), findsOneWidget);

    await tester.tap(find.byKey(const Key('diceCountField')));
    await tester.pumpAndSettle();
    for (var n = 1; n <= 9; n++) {
      expect(find.text('$n'), findsWidgets);
    }
    await tester.tap(find.text('7').last);
    await tester.pumpAndSettle();
    expect(settings.diceCount, 7);
    expect((await AppSettings.load()).diceCount, 7);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(Die), findsNWidgets(7));
  });

  testWidgets('"Sum of 2" to "Sum of 5" show only the total in a circle', (
    tester,
  ) async {
    // Tall enough for the whole menu to show without scrolling.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = await loadSettings();
    await tester.pumpWidget(
      RollTheDiceApp(settings: settings, vibrator: FakeVibrator()),
    );
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diceCountField')));
    await tester.pumpAndSettle();
    for (var n = 2; n <= 5; n++) {
      expect(find.text('Sum of $n'), findsWidgets);
    }
    expect(find.text('Sum of 1'), findsNothing);
    expect(find.text('Sum of 6'), findsNothing);
    await tester.tap(find.text('Sum of 3').last);
    await tester.pumpAndSettle();
    expect(settings.diceCount, 3);
    expect(settings.showSum, isTrue);
    final reloaded = await AppSettings.load();
    expect((reloaded.diceCount, reloaded.showSum), (3, true));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(Die), findsNothing);
    final circle = tester.getRect(find.byKey(const Key('sumCircle')));
    expect(circle.width, moreOrLessEquals(circle.height));
    final totals = <int>{};
    for (var i = 0; i < 30; i++) {
      await tester.tapAt(const Offset(10, 400));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.byKey(const Key('sumText')));
      totals.add(int.parse(text.data!));
    }
    expect(totals, everyElement(inInclusiveRange(3, 18)));
    expect(totals.length, greaterThan(5));
  });

  testWidgets('a stored sum of more than 5 dice falls back to plain dice', (
    tester,
  ) async {
    final s = await loadSettings({'diceCount': 8, 'showSum': true});
    expect((s.diceCount, s.showSum), (8, false));
  });

  testWidgets('ignores a stored number of dice outside 1 to 9', (tester) async {
    expect((await loadSettings({'diceCount': 0})).diceCount, 2);
    expect((await loadSettings({'diceCount': 10})).diceCount, 2);
  });

  int countOf(WidgetTester tester, int value) =>
      int.parse(tester.widget<Text>(find.byKey(Key('count$value'))).data!);

  testWidgets('stats are off by default; the switch shows and persists them', (
    tester,
  ) async {
    final settings = await loadSettings();
    expect(settings.showStats, isFalse);
    await tester.pumpWidget(
      RollTheDiceApp(settings: settings, vibrator: FakeVibrator()),
    );
    expect(find.byKey(const Key('histogram')), findsNothing);
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('statsSwitch')));
    await tester.pumpAndSettle();
    expect(settings.showStats, isTrue);
    expect((await AppSettings.load()).showStats, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('histogram')), findsOneWidget);
    for (var v = 1; v <= 6; v++) {
      expect(countOf(tester, v), 0);
    }
  });

  testWidgets('plain dice: one bucket per face, every die counts', (
    tester,
  ) async {
    final settings = await loadSettings({'showStats': true, 'diceCount': 3});
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(random: Random(7), settings: settings),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.tapAt(const Offset(400, 200));
      await tester.pumpAndSettle();
    }
    expect(settings.statCounts.length, 6);
    expect(settings.statCounts.fold(0, (a, b) => a + b), 30);
    for (var v = 1; v <= 6; v++) {
      expect(countOf(tester, v), settings.statCounts[v - 1]);
    }
    // The counts survive a reload.
    expect((await AppSettings.load()).statCounts, settings.statCounts);
  });

  testWidgets('sum mode: one bucket per possible total', (tester) async {
    final settings = await loadSettings({
      'showStats': true,
      'diceCount': 2,
      'showSum': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(random: Random(3), settings: settings),
      ),
    );
    expect(settings.statCounts.length, 11);
    expect(find.byKey(const Key('count2')), findsOneWidget);
    expect(find.byKey(const Key('count12')), findsOneWidget);
    expect(find.byKey(const Key('count1')), findsNothing);
    expect(find.byKey(const Key('count13')), findsNothing);
    await tester.tapAt(const Offset(400, 200));
    await tester.pumpAndSettle();
    final total = int.parse(
      tester.widget<Text>(find.byKey(const Key('sumText'))).data!,
    );
    expect(countOf(tester, total), 1);
    expect(settings.statCounts.fold(0, (a, b) => a + b), 1);
  });

  testWidgets('tapping the histogram asks to reset instead of rolling', (
    tester,
  ) async {
    final settings = await loadSettings({
      'showStats': true,
      'statCounts': ['1', '2', '3', '4', '5', '6'],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(random: Random(1), settings: settings),
      ),
    );
    expect(countOf(tester, 6), 6);

    await tester.tap(find.byKey(const Key('histogram')));
    await tester.pumpAndSettle();
    expect(find.text('Reset histogram?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resetNo')));
    await tester.pumpAndSettle();
    // No roll happened and nothing was reset.
    expect(settings.statCounts, [1, 2, 3, 4, 5, 6]);

    await tester.tap(find.byKey(const Key('histogram')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resetYes')));
    await tester.pumpAndSettle();
    expect(settings.statCounts, everyElement(0));
    expect(countOf(tester, 6), 0);
    expect((await AppSettings.load()).statCounts, everyElement(0));
  });

  testWidgets('changing the dice starts a new count', (tester) async {
    final settings = await loadSettings({
      'showStats': true,
      'statCounts': ['1', '2', '3', '4', '5', '6'],
    });
    settings.setDice(3, showSum: true);
    expect(settings.statCounts, List.filled(16, 0));
    expect(settings.statFirstValue, 3);
  });

  testWidgets('ignores stored counts that do not fit the dice', (tester) async {
    final s = await loadSettings({
      'statCounts': ['1', '2', 'x', '4', '5', '6'],
    });
    expect(s.statCounts, List.filled(6, 0));
    final t = await loadSettings({
      'diceCount': 2,
      'showSum': true,
      'statCounts': ['1', '2', '3', '4', '5', '6'],
    });
    expect(t.statCounts, List.filled(11, 0));
  });

  testWidgets('rolls are not counted while stats are off', (tester) async {
    final settings = await loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(random: Random(2), settings: settings),
      ),
    );
    await tester.tapAt(const Offset(400, 200));
    await tester.pumpAndSettle();
    expect(settings.statCounts, everyElement(0));
  });

  // Phone portrait, phone landscape, tablet, desktop.
  const screens = [
    Size(390, 844),
    Size(844, 390),
    Size(1024, 768),
    Size(1920, 1080),
  ];
  for (final screen in screens) {
    for (var n = 1; n <= 9; n++) {
      testWidgets('$n dice fit square on a ${screen.width.toInt()}x'
          '${screen.height.toInt()} screen', (tester) async {
        tester.view.physicalSize = screen;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final settings = await loadSettings({'diceCount': n});
        await tester.pumpWidget(RollTheDiceApp(settings: settings));

        expect(find.byType(Die), findsNWidgets(n));
        final rects = [
          for (var i = 0; i < n; i++) tester.getRect(find.byKey(Key('die$i'))),
        ];
        final screenRect = Offset.zero & screen;
        for (final r in rects) {
          expect(r.width, moreOrLessEquals(r.height), reason: 'square');
          expect(r.width, moreOrLessEquals(rects.first.width), reason: 'same');
          expect(r.width, greaterThan(40), reason: 'big enough to read');
          expect(screenRect.contains(r.topLeft), isTrue);
          expect(
            screenRect.contains(r.bottomRight - const Offset(1, 1)),
            isTrue,
          );
        }
        for (var i = 0; i < n; i++) {
          for (var j = i + 1; j < n; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse, reason: 'die $i/$j');
          }
        }
      });
    }
  }

  testWidgets('one tap rolls all the dice', (tester) async {
    final settings = await loadSettings({'diceCount': 9});
    await tester.pumpWidget(
      MaterialApp(
        home: DicePage(random: Random(7), settings: settings),
      ),
    );
    final changed = List.filled(9, false);
    for (var roll = 0; roll < 10; roll++) {
      final before = [for (var i = 0; i < 9; i++) pipsIn(tester, 'die$i')];
      await tester.tapAt(const Offset(10, 400));
      await tester.pumpAndSettle();
      for (var i = 0; i < 9; i++) {
        if (pipsIn(tester, 'die$i') != before[i]) changed[i] = true;
      }
    }
    expect(changed, everyElement(isTrue));
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
