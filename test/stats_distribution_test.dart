// Rolls many times through the real app (taps, animation, recordRoll) and
// checks the histograms against the probabilities of fair dice with a
// chi-square goodness-of-fit test. Takes about 8 minutes, so it is skipped
// by default; run it with:
//   flutter test --run-skipped -t slow
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roll_the_dice/main.dart';
import 'package:roll_the_dice/settings.dart';

const rolls = 10000;

/// P(total = n + k) for [n] fair six-sided dice, k = 0 .. 5n, by convolution.
List<double> sumProbabilities(int n) {
  var p = [1.0];
  for (var d = 0; d < n; d++) {
    final next = List.filled(p.length + 5, 0.0);
    for (var i = 0; i < p.length; i++) {
      for (var f = 0; f < 6; f++) {
        next[i + f] += p[i] / 6;
      }
    }
    p = next;
  }
  return p;
}

/// Merges neighbouring buckets until each expects at least 5, as the
/// chi-square approximation needs. Returns (observed, expected) pairs.
List<(int, double)> pool(List<int> observed, List<double> expected) {
  final out = <(int, double)>[];
  var o = 0;
  var e = 0.0;
  for (var i = 0; i < observed.length; i++) {
    o += observed[i];
    e += expected[i];
    if (e >= 5) {
      out.add((o, e));
      o = 0;
      e = 0;
    }
  }
  if (e > 0 || o > 0) {
    final (lo, le) = out.removeLast();
    out.add((lo + o, le + e));
  }
  return out;
}

double chiSquare(List<(int, double)> buckets) =>
    buckets.fold(0.0, (s, b) => s + (b.$1 - b.$2) * (b.$1 - b.$2) / b.$2);

/// Chi-square value that a fair die exceeds with probability 0.001
/// (Wilson–Hilferty approximation, z = 3.09).
double critical(int df) {
  final a = 2 / (9 * df);
  return df * pow(1 - a + 3.09 * sqrt(a), 3).toDouble();
}

void main() {
  for (final threeD in [false, true]) {
    for (final n in [1, 2, 3, 9]) {
      testWidgets(
        '$rolls rolls of $n ${threeD ? '3D' : '2D'} dice fit fair-dice '
        'probabilities',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'showStats': true,
            'diceCount': n,
            'fakeDelayMs': 1,
            'threeD': threeD,
          });
          final settings = await AppSettings.load();
          await tester.pumpWidget(
            MaterialApp(
              home: DicePage(random: Random(2026 + n), settings: settings),
            ),
          );
          for (var i = 0; i < rolls; i++) {
            await tester.tapAt(const Offset(400, 150));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 2));
          }
          expect(tester.hasRunningAnimations, isFalse);

          final faces = settings.faceCounts;
          final sums = settings.sumCounts;
          expect(faces.fold(0, (a, b) => a + b), rolls * n);
          expect(sums.fold(0, (a, b) => a + b), rolls);

          final faceBuckets = pool(faces, List.filled(6, rolls * n / 6));
          final sumBuckets = pool(sums, [
            for (final p in sumProbabilities(n)) p * rolls,
          ]);
          final faceChi = chiSquare(faceBuckets);
          final sumChi = chiSquare(sumBuckets);
          final faceDf = faceBuckets.length - 1;
          final sumDf = sumBuckets.length - 1;
          // ignore: avoid_print
          print(
            'RESULT threeD=$threeD n=$n faces=$faces sums=$sums '
            'faceChi=${faceChi.toStringAsFixed(2)} df=$faceDf '
            'sumChi=${sumChi.toStringAsFixed(2)} df=$sumDf',
          );
          expect(faceChi, lessThan(critical(faceDf)), reason: 'faces $faces');
          if (n > 1) {
            expect(sumChi, lessThan(critical(sumDf)), reason: 'sums $sums');
          }
        },
        tags: 'slow',
        timeout: const Timeout(Duration(minutes: 5)),
      );
    }
  }
}
