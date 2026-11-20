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
    for (final k in ['dieLeft', 'dieRight']) {
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
      seen.add((pipsIn(tester, 'dieLeft'), pipsIn(tester, 'dieRight')));
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
    await tester.pumpWidget(RollTheDiceApp(settings: settings));
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
